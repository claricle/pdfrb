# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Instance (s13.6.3). A single playable instance.
      class RichMediaInstance < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaInstance"
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def media_clip; self[:Asset]; end

        def flash?
          subtype == :Flash
        end

        def sound?
          subtype == :Sound
        end

        def video?
          subtype == :Video
        end

        def resolved_media_clip
          ref = media_clip
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
