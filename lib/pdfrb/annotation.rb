# frozen_string_literal: true

module Pdfrb
  # Annotation types (ISO 32000-2 §12.5). Each subtype is a thin builder
  # that produces a correctly-shaped annotation dictionary and registers
  # itself in the +Annotation::REGISTRY+ for open/closed extensibility.
  #
  # Adding a new annotation type = one new class + +register_as :Subtype+.
  # No switch edits anywhere in the codebase.
  module Annotation
    autoload :Base, "pdfrb/annotation/base"
    autoload :Types, "pdfrb/annotation/types"

    class << self
      # Build an annotation by subtype symbol.
      def create(subtype, document:, page:, **opts)
        klass = registry[subtype]
        return build_fallback(subtype, document, page, opts) unless klass

        klass.create(document: document, page: page, **opts)
      end

      def registry
        @registry ||= {}
      end

      def register(subtype, klass)
        registry[subtype] = klass
      end

      def [](subtype)
        registry[subtype]
      end

      def subtypes
        registry.keys
      end

      private

      def build_fallback(subtype, document, page, opts)
        Base.create(subtype, document: document, page: page, **opts)
      end
    end
  end
end

# Eager-load types so register_as calls populate REGISTRY.
require "pdfrb/annotation/types"
