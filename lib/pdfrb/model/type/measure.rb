# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Measure < Cos::Dictionary
        register_type :Measure

        def type; self[:Subtype]; end
        def scale_ratio; self[:RT]; end
        def x_scale; self[:X]; end
        def y_scale; self[:Y]; end
      end
    end
  end
end
