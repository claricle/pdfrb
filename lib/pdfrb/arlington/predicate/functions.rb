# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Registry of `fn:Name` predicate implementations. Each module
      # under Functions implements one or more predicates and
      # registers them on load via `register`.
      module Functions
        @registry = {}

        class << self
          attr_reader :registry

          def register(name, &block)
            @registry[name.to_s] = block
          end

          def clear!
            @registry.clear
          end
        end
      end
    end
  end
end

# Load built-in function groups. Each calls Functions.register on load.
require "pdfrb/arlington/predicate/functions/version"
require "pdfrb/arlington/predicate/functions/presence"
require "pdfrb/arlington/predicate/functions/logical"
require "pdfrb/arlington/predicate/functions/arithmetic"
require "pdfrb/arlington/predicate/functions/reference"
require "pdfrb/arlington/predicate/functions/file"
