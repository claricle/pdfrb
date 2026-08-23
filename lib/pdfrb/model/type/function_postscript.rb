# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 4 PostScript calculator function (s8.9.6). Carries a
      # PostScript program in the stream payload that computes the
      # output values from input values.
      class FunctionPostScript < Pdfrb::Model::Cos::Stream
        arlington_object "FunctionType4"
        def function_type; self[:FunctionType] || 4; end

        def domain; self[:Domain]; end
        def range; self[:Range]; end

        def postscript?
          true
        end

        def program
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
