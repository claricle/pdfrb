# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DeviceN Mixing Hints (s8.6.6.5). Per-colorant device hints.
      class DeviceNMixingHints < Pdfrb::Model::Cos::Dictionary
        arlington_object "DeviceNMixingHints"
        def solidities; self[:Solidities]; end
        def dot_gain; self[:DotGain]; end

        def has_solidities?
          !!solidities
        end
      end
    end
  end
end
