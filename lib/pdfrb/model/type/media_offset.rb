# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Media Offset Time (s13.3.6.5). Time-based media offset.
      class MediaOffsetTime < Pdfrb::Model::Cos::Dictionary
        def subtype; self[:S]&.to_sym; end
        def timespan; self[:T]; end

        def time_offset
          return nil unless timespan

          timespan.is_a?(Pdfrb::Model::Cos::Dictionary) ? timespan[:V] : timespan
        end
      end

      # Media Offset Frame (s13.3.6.5). Frame-based media offset.
      class MediaOffsetFrame < Pdfrb::Model::Cos::Dictionary
        def subtype; self[:S]&.to_sym; end
        def frame_number; self[:F]; end
        def time; self[:T]; end

        def has_frame?
          !!frame_number
        end
      end

      # Media Offset Marker (s13.3.6.5). Marker-based media offset.
      class MediaOffsetMarker < Pdfrb::Model::Cos::Dictionary
        def subtype; self[:S]&.to_sym; end
        def marker_name; self[:M]; end
      end

      # Media Player Info (s13.3.5.5). Identifies which players can
      # render the rendition.
      class MediaPlayerInfo < Pdfrb::Model::Cos::Dictionary
        def player_identifier; self[:PID]; end
        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end

        def has_constraints?
          !!must_honor || !!best_effort
        end

        def resolved_player_identifier
          ref = player_identifier
          return nil unless ref && document

          document.object(ref)
        end
      end

      # Media Players (s13.3.5.5). Player info lists.
      class MediaPlayers < Pdfrb::Model::Cos::Dictionary
        def must_use; self[:MU]; end
        def alternate; self[:A]; end
        def never_use; self[:NU]; end

        def must_use_count
          return 0 unless must_use

          arr = must_use.is_a?(Pdfrb::Model::PdfArray) ? must_use.to_a : must_use
          arr.is_a?(Array) ? arr.size : 0
        end

        def never_use_count
          return 0 unless never_use

          arr = never_use.is_a?(Pdfrb::Model::PdfArray) ? never_use.to_a : never_use
          arr.is_a?(Array) ? arr.size : 0
        end
      end

      # Media Screen Parameters (s13.3.5.4). Controls how media is
      # displayed on the screen annotation.
      class MediaScreenParameters < Pdfrb::Model::Cos::Dictionary
        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end
        def fit; self[:FIT]; end

        def fit_meet?; fit == :Meet; end
        def fit_slice?; fit == :Slice; end
        def fit_fill?; fit == :Fill; end
        def fit_hidden?; fit == :Hidden; end
        def fit_tiled?; fit == :Tiled; end
      end

      # Media Criteria (s13.3.5.5). Constraints when selecting players.
      class MediaCriteria < Pdfrb::Model::Cos::Dictionary
        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end
        def bit_rate; self[:Rate]; end
        def bandwidth; self[:RateBS]; end
        def cpu; self[:RateCpu]; end
        def ram; self[:RateRam]; end
        def language; self[:Lang]; end
        def mime_type; self[:MimeType]; end

        def has_bit_rate_constraint?
          !!bit_rate
        end
      end
    end
  end
end
