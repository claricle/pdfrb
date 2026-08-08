# frozen_string_literal: true

module Pdfrb
  # Actions (ISO 32000-2 §12.6). An action specifies an interactive
  # behavior: jump to a destination, open a URI, launch an app, etc.
  #
  # Each action type is a value object that serializes to a PDF action
  # dictionary with /S (action type) and type-specific keys.
  module Action
    autoload :Base, "pdfrb/action/base"
    # Each action builder class lives in types.rb but is referenced
    # directly by callers. Autoload from that file.
    autoload :GoTo, "pdfrb/action/types"
    autoload :URI, "pdfrb/action/types"
    autoload :Launch, "pdfrb/action/types"
    autoload :Named, "pdfrb/action/types"
    autoload :GoToR, "pdfrb/action/types"
    autoload :SubmitForm, "pdfrb/action/types"
    autoload :ResetForm, "pdfrb/action/types"
    autoload :JavaScript, "pdfrb/action/types"
    autoload :Hide, "pdfrb/action/types"
    autoload :ImportData, "pdfrb/action/types"
    autoload :SetOCGState, "pdfrb/action/types"
    autoload :Trans, "pdfrb/action/types"
    autoload :GoToE, "pdfrb/action/types"

    class << self
      def registry
        @registry ||= {}
      end

      def register(name, klass)
        registry[name.to_sym] = klass
      end

      def [](name)
        key = name.to_sym
        result = registry[key]
        return result if result

        # Lazy-load on miss: trigger autoload of GoTo which loads
        # the entire types.rb file and registers all subtypes.
        GoTo unless @loaded
        @loaded = true
        registry[key]
      end

      def types
        GoTo unless @loaded
        @loaded = true
        registry.keys
      end
    end
  end
end
