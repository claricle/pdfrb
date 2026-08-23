# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Animation (s13.6.2). Playback control for
      # rich media instances.
      class RichMediaAnimation < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaAnimation"
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def play_count; self[:PlayCount] || -1; end
        def speed; self[:Speed] || 1; end
        def animation_offset; self[:AO] || 0; end

        def no_animation?; subtype == :None; end
        def linear?; subtype == :Linear; end
        def oscillating?; subtype == :Oscillating; end

        def loop_forever?
          play_count.negative?
        end
      end
    end
  end
end
