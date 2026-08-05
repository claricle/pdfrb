# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # IconFit (s12.5.6.19). Controls positioning/scaling of a button
      # field's icon within its rectangle.
      class IconFit < Cos::Dictionary
        register_type :IconFit

        def type; self[:Type]; end
        def scale_type; self[:SW]&.to_sym; end
        def fit; self[:S]&.to_sym; end
        def always_scaled?; scale_type.nil? || scale_type == :A; end
        def scale_when_bigger?; scale_type == :B; end
        def scale_when_smaller?; scale_type == :S; end
        def never_scale?; scale_type == :N; end
        def proportional_fit?; fit.nil? || fit == :P; end
        def non_proportional_fit?; fit == :A; end

        def border_background; self[:BG]; end
        def border_arrow_left; self[:IF]; end
        def tp; self[:TP]; end

        def placement_mode
          tp || 0
        end
      end
    end
  end
end
