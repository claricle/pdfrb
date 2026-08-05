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
    end
  end
end
