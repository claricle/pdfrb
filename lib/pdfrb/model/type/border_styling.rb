# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class BorderStyling < Cos::Dictionary
        register_type :BorderStyling

        def style; self[:S]; end
        def width; self[:W] || 1.0; end
        def dash; self[:D]; end
      end
    end
  end
end
