# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # Logical predicates that don't fit Ruby's native && / || / !
        # dispatch: Eval (run a sub-expression), Not (alias for !).
        module LogicalPredicates
          module_function

          def register_all
            Functions.register("Eval") do |args, _ctx|
              # Eval is special: its single argument is already
              # evaluated by the time we get it (because the Evaluator
              # walks args eagerly). So we just return the value as-is.
              args.first
            end

            Functions.register("Not") do |args, _ctx|
              !args.first
            end

            Functions.register("And") do |args, _ctx|
              args.all? { |a| a }
            end

            Functions.register("Or") do |args, _ctx|
              args.any? { |a| a }
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::LogicalPredicates.register_all
