# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Appearance Characteristics dictionary (s12.5.5). Defines the
      # visual characteristics of a widget annotation: background/caption
      # colors, normal/rollover/down captions, etc. Often stored under
      # the widget's /MK key.
      class AppearanceCharacteristics < Pdfrb::Model::Cos::Dictionary
        def background_color; self[:BG]; end
        def caption; self[:CA]; end
        def rollover_caption; self[:RC]; end
        def down_caption; self[:AC]; end
        def rotation; self[:R] || 0; end
        def border_color; self[:BC]; end
        def normal_icon; self[:IF]; end
        def alternate_icon; self[:IX]; end
        def icon_fit; self[:IF]; end
        def tp; self[:TP]; end

        def text_position
          tp || 0
        end

        def has_background?
          !!background_color
        end

        def has_caption?
          !!caption
        end
      end

      # Appearance stream dictionary (s12.5.5). The /AP dict on an
      # annotation holds three sub-dicts: /N (normal), /R (rollover),
      # /D (down).
      class Appearance < Pdfrb::Model::Cos::Dictionary
        def normal; self[:N]; end
        def rollover; self[:R]; end
        def down; self[:D]; end

        def has_normal?
          !!normal
        end

        def has_rollover?
          !!rollover
        end

        def has_down?
          !!down
        end

        def normal_for_state(state_name)
          return nil unless normal

          n = if normal.is_a?(Pdfrb::Model::Reference) && document
                document.object(normal)
              else
                normal
              end
          return nil unless n.respond_to?(:[])

          n[state_name]
        end
      end

      # Media Clip Data stream (s13.3.3). Carries actual media payload.
      class MediaClip < Pdfrb::Model::Cos::Stream
        def type; self[:Type]; end
        def subtype; self[:S]&.to_sym; end

        def must_use_honest?
          subtype == :MIMEType
        end

        def file_spec; self[:D]; end
        def mime_type; self[:CT]; end
        def data_size; self[:S]; end

        def resolved_file_spec
          ref = file_spec
          return nil unless ref && document

          document.object(ref)
        end
      end

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
