# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Registry of `fn:Name` predicate implementations. Each module
      # under Functions implements one or more predicates and
      # registers them on load via `register`.
      module Functions
        @registry = {}

        autoload :VersionPredicates, "pdfrb/arlington/predicate/functions/version"
        autoload :PresencePredicates, "pdfrb/arlington/predicate/functions/presence"
        autoload :LogicalPredicates, "pdfrb/arlington/predicate/functions/logical"
        autoload :ArithmeticPredicates, "pdfrb/arlington/predicate/functions/arithmetic"
        autoload :ReferencePredicates, "pdfrb/arlington/predicate/functions/reference"
        autoload :FilePredicates, "pdfrb/arlington/predicate/functions/file"

        class << self
          def registry
            eager_load! unless @eager_loaded
            @registry
          end

          def register(name, &block)
            @registry[name.to_s] = block
          end

          def clear!
            @registry.clear
          end

          # Force-load all function groups so register calls fire.
          # Idempotent.
          def eager_load!
            return if @eager_loaded

            constants.each do |c|
              const_get(c)
            rescue NameError, LoadError
              # Skip autoload targets that don't define a class
              # or whose file doesn't exist yet.
            end
            @eager_loaded = true
          end
        end
      end
    end
  end
end
