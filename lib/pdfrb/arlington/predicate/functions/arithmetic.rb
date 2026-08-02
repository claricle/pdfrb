# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # Arithmetic helpers: ArrayLength, StringLength, RequiredValue,
        # BitSet, BitsClear, BitsSet, KeyNameIsColorant.
        module ArithmeticPredicates
          module_function

          def register_all
            Functions.register("ArrayLength") do |args, ctx|
              key = args.first
              val = ctx.current && ctx.current[key.to_sym]
              val = val.to_a if val.is_a?(Pdfrb::Model::PdfArray)
              val.is_a?(::Array) ? val.length : 0
            end

            Functions.register("StringLength") do |args, ctx|
              key = args.first
              val = ctx.current && ctx.current[key.to_sym]
              val.is_a?(::String) ? val.bytesize : 0
            end

            Functions.register("RequiredValue") do |_args, _ctx|
              # Caller wraps as RequiredValue(@X == Y); the comparison
              # happens in BinOp, this just passes through.
              true
            end

            Functions.register("BitSet") do |args, _ctx|
              value, bit = args
              next false unless value.is_a?(::Integer) && bit.is_a?(::Integer)

              (value & (1 << bit)).nonzero?
            end

            Functions.register("BitsClear") do |args, _ctx|
              value, mask = args
              next false unless value.is_a?(::Integer) && mask.is_a?(::Integer)

              (value & mask).zero?
            end

            Functions.register("BitsSet") do |args, _ctx|
              value, mask = args
              next false unless value.is_a?(::Integer) && mask.is_a?(::Integer)

              (value & mask) == mask
            end

            Functions.register("KeyNameIsColorant") do |_args, _ctx|
              false # consumer-side; default to false
            end

            Functions.register("NoCycle") do |_args, _ctx|
              true # consumer-side; assume no cycles until proven
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::ArithmeticPredicates.register_all
