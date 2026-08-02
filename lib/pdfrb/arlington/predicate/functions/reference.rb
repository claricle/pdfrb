# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # Reference-shape predicates: MustBeDirect, MustBeIndirect.
        # These are mostly used in the IndirectReference column of
        # TSVs to override the TRUE/FALSE default.
        module ReferencePredicates
          module_function

          def register_all
            Functions.register("MustBeDirect") do |_args, _ctx|
              true # semantically: the field must be a direct object
            end

            Functions.register("MustBeIndirect") do |_args, _ctx|
              true # semantically: the field must be an indirect object
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::ReferencePredicates.register_all
