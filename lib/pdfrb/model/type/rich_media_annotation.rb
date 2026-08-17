# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media annotation (s12.5.6.20, PDF 1.7 ExtensionLevel 3 +
      # PDF 2.0). Hosts interactive rich media content (Flash, video).
      class RichMediaAnnotation < Annotation
        arlington_object "AnnotRichMedia"
        def rich_media_settings; self[:RichMediaSettings]; end
        def rich_media_content; self[:RichMediaContent]; end

        def has_rich_media?
          !!rich_media_content
        end
      end
    end
  end
end
