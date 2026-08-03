# frozen_string_literal: true

module Pdfrb
  # Actions (ISO 32000-2 §12.6). An action specifies an interactive
  # behavior: jump to a destination, open a URI, launch an app, etc.
  #
  # Each action type is a value object that serializes to a PDF action
  # dictionary with /S (action type) and type-specific keys.
  module Action
    autoload :Base, "pdfrb/action/base"
    autoload :Types, "pdfrb/action/types"

    class << self
      def registry
        @registry ||= {}
      end

      def register(name, klass)
        registry[name.to_sym] = klass
      end

      def [](name)
        registry[name.to_sym]
      end

      def types
        registry.keys
      end
    end
  end
end

# Eager-load types so register_as calls populate REGISTRY.
require "pdfrb/action/types"
