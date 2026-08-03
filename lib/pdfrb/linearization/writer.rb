# frozen_string_literal: true

require "set"
require "stringio"
require "zlib"

module Pdfrb
  module Linearization
    # Writes a PDF in linearized format (ISO 32000-2 §7.6.2, Annex F).
    #
    # Approach: serialize all objects to a temp buffer, compute final
    # offsets, then assemble the file with the linearization parameter
    # dict as the first indirect object. The lin dict values (/L, /H,
    # /O, /E, /N, /T) are filled from the computed layout.
    #
    # This produces a structurally valid linearized PDF with page-offset
    # hints. Full optimization (shared-object tables, minimal-download
    # ordering) is future work.
    class Writer
      # Internal value object carrying computed offsets through assembly.
      Layout = Struct.new(
        :lin_dict_offset, :lin_dict_size,
        :hint_offset, :hint_length,
        :first_page_oid, :first_page_end,
        :xref_offset, :total_size, :num_pages,
        :ordered_objects, :hint_oid,
        :hint_dict, :hint_compressed,
        :xref_bytes, :trailer_bytes,
        keyword_init: true
      )

      def initialize(document)
        @document = document
        @serializer = Pdfrb::Serializer.new
      end

      # @param io [IO] target output.
      # @return [void]
      def write(io)
        io.binmode

        pages = collect_pages
        return write_non_linearized(io) if pages.length < 2

        layout = compute_layout(pages)
        assembled = assemble_file(pages, layout)
        io.write(assembled)
      end

      private

      def collect_pages
        @document.pages.each.to_a
      end

      def compute_layout(pages) # rubocop:disable Metrics/MethodLength
        all_objects = @document.each_indirect_object.to_a
        first_page_closure = object_closure(pages.first)
        first_page_objects, rest_objects = all_objects.partition { |o| first_page_closure.include?(o.oid) }

        ordered = first_page_objects + rest_objects
        hint_oid = @document.next_oid || 1

        offsets = {}
        temp = StringIO.new
        temp.binmode
        temp << header_bytes
        lin_dict_size = estimate_lin_dict_size(pages.length)
        lin_dict_offset = temp.pos
        temp.write("X" * lin_dict_size)

        ordered.each do |obj|
          offsets[obj.oid] = temp.pos
          temp << @serializer.serialize_indirect(obj)
        end
        first_page_end = temp.pos if first_page_objects.any?

        hint = build_hint_stream(pages, offsets)
        hint_data = hint.encode
        hint_compressed = ::Zlib::Deflate.deflate(hint_data)
        hint_offset = temp.pos
        hint_dict = @serializer.serialize(
          Type: :XRef,
          S: HintStream::DEFAULT_ITEM_BITS,
          Filter: :FlateDecode,
          Length: hint_compressed.bytesize
        )
        temp << "#{hint_oid} 0 obj\n"
        temp << hint_dict
        temp << "\nstream\n"
        temp << hint_compressed
        temp << "\nendstream\nendobj\n"
        offsets[hint_oid] = hint_offset

        xref_offset = temp.pos
        xref_bytes = build_xref(offsets)
        temp << xref_bytes
        temp << build_trailer(xref_offset)

        Layout.new(
          lin_dict_offset: lin_dict_offset,
          lin_dict_size: lin_dict_size,
          hint_offset: hint_offset,
          hint_length: hint_compressed.bytesize,
          first_page_oid: pages.first.oid,
          first_page_end: first_page_end || temp.pos,
          xref_offset: xref_offset,
          total_size: temp.pos,
          num_pages: pages.length,
          ordered_objects: ordered,
          hint_oid: hint_oid,
          hint_dict: hint_dict,
          hint_compressed: hint_compressed,
          xref_bytes: xref_bytes,
          trailer_bytes: build_trailer(xref_offset)
        )
      end

      def assemble_file(_pages, layout)
        buf = String.new(encoding: Encoding::BINARY)
        buf << header_bytes.b

        lin_dict = serialize_lin_dict(
          total_size: layout.total_size,
          hint_offset: layout.hint_offset,
          hint_length: layout.hint_length,
          first_page_oid: layout.first_page_oid,
          first_page_end: layout.first_page_end,
          num_pages: layout.num_pages,
          xref_offset: layout.xref_offset
        )
        lin_padded = pad_to_size(lin_dict, layout.lin_dict_size)
        buf << lin_padded

        layout.ordered_objects.each do |obj|
          buf << @serializer.serialize_indirect(obj)
        end

        buf << "#{layout.hint_oid} 0 obj\n"
        buf << layout.hint_dict
        buf << "\nstream\n"
        buf << layout.hint_compressed
        buf << "\nendstream\nendobj\n"

        buf << layout.xref_bytes
        buf << layout.trailer_bytes

        buf.force_encoding(Encoding::BINARY)
      end

      def serialize_lin_dict(total_size:, hint_offset:, hint_length:,
                             first_page_oid:, first_page_end:, num_pages:, xref_offset:)
        dict_str = @serializer.serialize(
          Linearized: 1,
          L: total_size,
          H: Pdfrb::Model::PdfArray.new([hint_offset, hint_length]),
          O: first_page_oid,
          E: first_page_end,
          N: num_pages,
          T: xref_offset
        )
        "1 0 obj\n#{dict_str}\nendobj\n"
      end

      def pad_to_size(str, target_size)
        return str if str.bytesize >= target_size

        str + ("\n" * (target_size - str.bytesize))
      end

      def estimate_lin_dict_size(_num_pages)
        300
      end

      def build_hint_stream(pages, offsets)
        hint = HintStream.new
        base_offset = offsets[pages.first.oid] || 0

        pages.each do |page|
          offset = offsets[page.oid] || 0
          hint.add_page(
            offset_delta: offset - base_offset,
            page_length: 200,
            num_objects: 1,
            page_obj_num: page.oid
          )
        end
        hint
      end

      def object_closure(root)
        seen = Set.new
        queue = [root]

        until queue.empty?
          obj = queue.shift
          next if seen.include?(obj.oid)

          seen << obj.oid

          value = obj.is_a?(Pdfrb::Model::Object) ? obj.value : obj
          walk_for_refs(value) do |ref|
            child = @document.object(ref)
            queue << child if child && !seen.include?(child.oid)
          end
        end

        seen
      end

      def walk_for_refs(value, &block)
        case value
        when ::Hash
          value.each_value { |v| walk_for_refs(v, &block) }
        when ::Array, Pdfrb::Model::PdfArray
          value.each { |v| walk_for_refs(v, &block) }
        when Pdfrb::Model::Reference
          yield value
        end
      end

      def build_xref(offsets)
        buf = +""
        oids = offsets.keys.sort
        max_oid = oids.max || 0
        buf << "xref\n"
        buf << "0 #{max_oid + 1}\n"
        buf << "0000000000 65535 f \r\n"
        (1..max_oid).each do |oid|
          off = offsets[oid]
          buf << if off
                   sprintf("%010d %05d n \r\n", off, 0)
                 else
                   "0000000000 00000 f \r\n"
                 end
        end
        buf
      end

      def build_trailer(xref_offset)
        root = @document.catalog
        root_ref = if root.is_a?(Pdfrb::Model::Object) && root.indirect?
                     Pdfrb::Model::Reference.new(root.oid, root.gen)
                   end
        size = [@document.next_oid || 1, 2].max

        trailer_str = @serializer.serialize(Size: size, Root: root_ref)
        "trailer\n#{trailer_str}\nstartxref\n#{xref_offset}\n%%EOF\n"
      end

      def header_bytes
        "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n"
      end

      def write_non_linearized(io)
        Pdfrb::Writer.write(@document, io)
      end
    end
  end
end
