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

      # Movie activation dictionary (s12.5.6.14, /A): playback
      # parameters for a movie annotation.
      class MovieActivation < Pdfrb::Model::Cos::Dictionary
        arlington_object "MovieActivation"

        def start; self[:Start]; end
        def duration; self[:Duration]; end
        def rate; self[:Rate]; end
        def volume; self[:Volume]; end
        def show_controls; self[:ShowControls]; end
        def synchronous; self[:Synchronous]; end
        def fw_scale; self[:FWScale]; end
      end
    end
  end
end
