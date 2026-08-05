# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PDF Function dictionary (s8.9.1). Functions map input values to
      # output values; used by shadings, color spaces, and other
      # computational graphics primitives.
      #
      # Four function types exist (s8.9.4..7):
      #   * Type 0: Sampled (N-dimensional lookup table)
      #   * Type 2: Exponential (C0 + (C1 - C0) * t^r)
      #   * Type 3: Stitching (concatenation of multiple subfunctions)
      #   * Type 4: PostScript calculator (most flexible)
      class Function < Pdfrb::Model::Cos::Dictionary
        def function_type; self[:FunctionType]; end

        def domain; self[:Domain]; end
        def range; self[:Range]; end

        def sampled?; function_type.zero?; end
        def exponential?; function_type == 2; end
        def stitching?; function_type == 3; end
        def postscript?; function_type == 4; end

        def input_dimension
          return nil unless domain

          arr = domain.is_a?(Pdfrb::Model::PdfArray) ? domain.to_a : domain
          arr.is_a?(Array) ? arr.size / 2 : nil
        end

        def output_dimension
          return nil unless range

          arr = range.is_a?(Pdfrb::Model::PdfArray) ? range.to_a : range
          arr.is_a?(Array) ? arr.size / 2 : nil
        end
      end
    end
  end
end
