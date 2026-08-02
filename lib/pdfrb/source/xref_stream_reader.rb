# frozen_string_literal: true

module Pdfrb
  module Source
    # Reads an XRef stream (s7.5.8, PDF 1.5+). The stream's decoded
    # bytes contain the xref entries; /W gives the byte widths of the
    # three fields (type, oid-or-next-free, gen-or-index).
    module XrefStreamReader
      module_function

      def read(stream_object, document)
        dict = stream_object
        decoded = stream_object.decoded_stream
        w = dict[:W].to_a
        raise Pdfrb::ParseError, "XRef stream missing /W" if w.nil? || w.length != 3

        index = (dict[:Index] || [0, dict[:Size]]).to_a
        section = XrefSection.new(size: dict[:Size] || 0)
        pos = 0
        bytes = decoded.bytes
        (index.length / 2).times do |seg|
          start_oid = index[seg * 2]
          count = index[seg * 2 + 1]
          count.times do |i|
            type = read_field(bytes, pos, w[0]) || 1
            pos += w[0]
            f2 = read_field(bytes, pos, w[1])
            pos += w[1]
            f3 = read_field(bytes, pos, w[2])
            pos += w[2]
            oid = start_oid + i
            case type
            when 0 then section.add_free(oid, f3 || 0, f2 || 0)
            when 1 then section.add_in_use(oid, f3 || 0, f2 || 0)
            when 2 then section.add_compressed(oid, f2 || 0, f3 || 0)
            end
          end
        end
        section
      end

      def read_field(bytes, pos, width)
        return nil if width.zero?

        val = 0
        width.times { |i| val = (val << 8) | (bytes[pos + i] || 0) }
        val
      end
      private_class_method :read_field
    end
  end
end
