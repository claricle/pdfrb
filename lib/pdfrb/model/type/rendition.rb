# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rendition dictionary (s13.3.5). Describes a media clip plus
      # how it should be played.
      class Rendition < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def subtype; self[:S]&.to_sym; end
        def media_clip; self[:C]; end
        def operation; self[:OP]; end

        def media?
          subtype == :MR
        end

        def selector?
          subtype == :SR
        end

        def resolved_media_clip
          ref = media_clip
          return nil unless ref && document

          document.object(ref)
        end
      end

      # Media rendition /S /MR (s13.3.5): plays a media clip.
      class RenditionMedia < Rendition
        arlington_object "RenditionMedia"

        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end
        def media_permissions; self[:P]; end
        def visible_on_page?; self[:SP] != false; end
      end

      # Selector rendition /S /SR (s13.3.5): picks among renditions.
      class RenditionSelector < Rendition
        arlington_object "RenditionSelector"

        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end
        def renditions; self[:R]; end
      end

      # Must-honor parameter wrapper {C: params} (s13.2.2): the
      # conforming reader must satisfy these or abort.
      class RenditionMH < Pdfrb::Model::Cos::Dictionary
        arlington_object "RenditionMH"

        def parameters; self[:C]; end
      end

      # Best-effort parameter wrapper {C: params} (s13.2.2).
      class RenditionBE < Pdfrb::Model::Cos::Dictionary
        arlington_object "RenditionBE"

        def parameters; self[:C]; end
      end
    end
  end
end
