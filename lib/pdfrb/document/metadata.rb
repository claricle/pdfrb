# frozen_string_literal: true

module Pdfrb
  class Document
    class Metadata
      STANDARD_FIELDS = %i[Title Author Subject Keywords Creator
                           Producer CreationDate ModDate Trapped].freeze

      attr_reader :document

      def initialize(document)
        @document = document
      end

      STANDARD_FIELDS.each do |field|
        define_method(field.downcase) { read_field(field) }
        define_method("#{field.downcase}=") { |v| write_field(field, v) }
      end

      def [](field)
        read_field(field)
      end

      def []=(field, value)
        write_field(field, value)
      end

      def to_xmp
        begin
          packet = Pdfrb::XMP::Packet.new
        rescue StandardError
          return ""
        end
        title = read_field(:Title)
        packet.title = title if title
        packet.to_xmp
      end

      private

      def read_field(field)
        info = info_dict
        return nil unless info

        raw = info.value[field]
        return nil if raw.nil?

        # Info values are text strings (s7.9.2.2): they may arrive as
        # UTF-16BE+BOM or PDFDocEncoding bytes (decryption hands back
        # wire bytes). Decode rather than relabel the encoding.
        raw.is_a?(::String) ? Pdfrb::Model::Cos::StringEncoding.decode_text(raw) : raw
      end

      def write_field(field, value)
        info = info_dict(create: true)
        info.value[field] = value.to_s
      end

      def info_dict(create: false)
        return @cached_info if defined?(@cached_info) && @cached_info

        trailer = document.trailer
        ref = trailer ? trailer[:Info] : nil
        obj = ref ? document.object(ref) : nil

        if obj.nil? && create
          obj = document.add({}, type: Pdfrb::Model::Type::Info)
          document.trailer[:Info] = obj.ref
        end
        @cached_info = obj
      end
    end
  end
end
