# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # Presence predicates: IsRequired, IsPresent, NotPresent.
        # These return Booleans.
        module PresencePredicates
          module_function

          def register_all
            Functions.register("IsRequired") do |args, ctx|
              # If a single predicate arg, evaluate its truthiness.
              # If no args, default to true.
              args.empty? ? true : !!args.first
            end

            Functions.register("IsPresent") do |args, ctx|
              next false if args.empty?

              key = args.first
              ctx.current && !ctx.current[key.to_sym].nil?
            end

            Functions.register("NotPresent") do |args, ctx|
              next true if args.empty?

              key = args.first
              ctx.current.nil? || ctx.current[key.to_sym].nil?
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::PresencePredicates.register_all
