# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 2 Exponential interpolation function (s8.9.4).
      # Maps +t+ ∈ [0,1] to C0 + (C1 - C0) * t^N.
      # Commonly used for 2-color linear gradients.
      class FunctionExponential < Function
        def c0; self[:C0]; end
        def c1; self[:C1]; end
        def exponent; self[:N] || 1; end

        def linear?
          exponent == 1
        end

        def evaluate(t)
          return nil unless c0 && c1

          arr0 = c0.is_a?(Pdfrb::Model::PdfArray) ? c0.to_a : c0
          arr1 = c1.is_a?(Pdfrb::Model::PdfArray) ? c1.to_a : c1
          n = exponent.to_f
          arr0.each_with_index.map do |a, i|
            a.to_f + ((arr1[i].to_f - a.to_f) * (t**n))
          end
        end
      end
    end
  end
end
