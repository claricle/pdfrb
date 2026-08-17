# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # BorderEffect (ISO 32000-2 §12.5.4.2, PDF 1.5+). Cloudy /
      # inset border effects for annotations, via the /BE dict.
      class BorderEffect < Pdfrb::Model::Cos::Dictionary
        arlington_object "BorderEffect"
        register_type :BorderEffect

        def type; self[:Type]; end
        def style; (self[:S] || :S).to_sym; end
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
