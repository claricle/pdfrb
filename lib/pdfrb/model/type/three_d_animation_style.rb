# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Animation Style (s13.6.3, Table 312-313). Animation control
      # for a 3D stream.
      class ThreeDAnimationStyle < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def play_count; self[:PC] || 0; end
        def time_multiplier; self[:TM] || 1; end

        def no_animation?; subtype == :None; end
        def linear?; subtype == :Linear; end
        def oscillating?; subtype == :Oscillating; end

        def loop_forever?
          play_count.zero?
        end
      end
    end
  end
end
