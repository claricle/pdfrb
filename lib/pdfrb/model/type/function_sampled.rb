# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 0 Sampled function (s8.9.3). N-dimensional lookup table
      # with interpolation. Carries sample data in the stream payload.
      class FunctionSampled < Pdfrb::Model::Cos::Stream
        def function_type; self[:FunctionType] || 0; end

        def domain; self[:Domain]; end
        def range; self[:Range]; end
        def size; self[:Size]; end
        def bits_per_sample; self[:BitsPerSample]; end
        def encode; self[:Encode]; end
        def decode; self[:Decode]; end

        def sampled?
          true
        end

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

        def sample_count
          return 1 unless size

          arr = size.is_a?(Pdfrb::Model::PdfArray) ? size.to_a : size
          return 1 unless arr.is_a?(Array) && !arr.empty?

          arr.reduce(1) { |product, n| product * n.to_i }
        end

        def bit_depth_8?
          bits_per_sample == 8
        end

        def bit_depth_16?
          bits_per_sample == 16
        end
      end
    end
  end
end
