# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class BorderEffect < Cos::Dictionary
        register_type :BorderEffect
        def style; self[:S]; end
        def intensity; self[:I] || 0; end
      end
    end
  end
end
