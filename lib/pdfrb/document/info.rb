# frozen_string_literal: true

module Pdfrb
  class Document
    # Document Info dictionary facade (PDF 1.x metadata on /Info).
    # Also bridges to XMP packet so both metadata representations stay
    # in sync. PDF 2.0 deprecates /Info in favor of XMP-only, but
    # /Info is still required for backward compatibility.
    class Info
      attr_reader :document

      def initialize(document)
        @document = document
      end

      FIELD_MAP = {
        title: :Title,
        author: :Author,
        subject: :Subject,
        keywords: :Keywords,
        creator: :Creator,
        producer: :Producer,
      }.freeze

      FIELD_MAP.each do |method_name, pdf_key|
        define_method(method_name) do
          info_dict[pdf_key]
        end

        define_method("#{method_name}=") do |value|
          set_info_field(pdf_key, value)
        end
      end

      def creation_date
        info_dict[:CreationDate]
      end

      def creation_date=(value)
        set_info_field(:CreationDate, pdf_date(value))
      end

      def mod_date
        info_dict[:ModDate]
      end

      def mod_date=(value)
        set_info_field(:ModDate, pdf_date(value))
      end

      def trapped
        info_dict[:Trapped]
      end

      def trapped=(value)
        set_info_field(:Trapped, value)
      end

      # Returns the /Info dictionary object (creating one if needed).
      def info_dict
        info_ref = document.trailer && document.trailer[:Info]
        return document.object(info_ref) if info_ref

        info = document.add({}, type: Pdfrb::Model::Cos::Dictionary)
        if document.trailer
          document.trailer[:Info] = info.ref
        end
        info
      end

      private

      def set_info_field(field, value)
        return if value.nil?

        dict = info_dict
        stored = field == :Trapped ? value : value.to_s
        dict.value[field] = stored
        sync_xmp(field, value)
      end

      def sync_xmp(field, value)
        case field
        when :Title then document.xmp.title = value
        when :Author then document.xmp.creator = value
        when :Subject then document.xmp.description = value
        when :Keywords then document.xmp.keywords = value
        when :Creator then document.xmp.creator_tool = value
        when :Producer then document.xmp.producer = value
        end
      end

      def pdf_date(time)
        return time.to_s if time.is_a?(::String)

        t = time.is_a?(::Time) ? time : Time.now
        utc = t.utc
        "D:#{utc.strftime('%Y%m%d%H%M%S')}+00'00'"
      end
    end
  end
end
