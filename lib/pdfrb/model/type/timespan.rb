# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Timespan (ISO 32000-2 §12.7.11, PDF 1.5+). A duration with
      # a unit, used in RichMedia timing, 3D animation, and
      # JavaScript-embedded timelines.
      class Timespan < Pdfrb::Model::Cos::Dictionary
        arlington_object "Timespan"

        # /Type — optional, fixed "Timespan".
        def type
          value[:Type]&.to_sym
        end

        # /S — required, fixed "S" (seconds).
        def subtype
          value[:S]&.to_sym
        end

        # /V — required, the numeric duration in seconds.
        def duration
          value[:V]
        end

        # Convenience: duration in milliseconds.
        def milliseconds
          v = duration
          v ? v.to_f * 1000 : nil
        end
      end
    end
  end
end
