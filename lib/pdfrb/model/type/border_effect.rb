# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # BorderEffect (s12.5.4.2). Cloudy / inset border effects for
      # annotations.
      class BorderEffect < Cos::Dictionary
        register_type :BorderEffect

        def type; self[:Type]; end
        def style; self[:S]&.to_sym; end
        def intensity; self[:I] || 0; end

        def cloudy?
          style == :C
        end

        def inset?
          style == :I
        end
      end
    end
  end
end
