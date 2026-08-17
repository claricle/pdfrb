# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Movie dictionary (s13.4). Deprecated since PDF 2.0 but still
      # appears in legacy PDFs. Use Screen + Rendition actions instead.
      class Movie < Pdfrb::Model::Cos::Dictionary
        arlington_object "Movie"
        def type; self[:Type]; end
        def file_spec; self[:F]; end
        def aspect; self[:Aspect]; end
        def rotate; self[:Rotate] || 0; end
        def poster; self[:Poster]; end

        def has_poster?
          !!poster
        end

        def resolved_file_spec
          ref = file_spec
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
