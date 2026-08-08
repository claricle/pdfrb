# frozen_string_literal: true

module Pdfrb
  # Annotation types (ISO 32000-2 §12.5). Each subtype is a thin builder
  # that produces a correctly-shaped annotation dictionary and registers
  # itself in the +Annotation::REGISTRY+ for open/closed extensibility.
  module Annotation
    autoload :Base, "pdfrb/annotation/base"
    autoload :Types, "pdfrb/annotation/types"
    # Each annotation builder class lives in types.rb. Autoload from
    # that file so direct class references work.
    autoload :Text, "pdfrb/annotation/types"
    autoload :Link, "pdfrb/annotation/types"
    autoload :FreeText, "pdfrb/annotation/types"
    autoload :Stamp, "pdfrb/annotation/types"
    autoload :Popup, "pdfrb/annotation/types"
    autoload :FileAttachment, "pdfrb/annotation/types"
    autoload :Highlight, "pdfrb/annotation/types"
    autoload :Underline, "pdfrb/annotation/types"
    autoload :Squiggly, "pdfrb/annotation/types"
    autoload :StrikeOut, "pdfrb/annotation/types"
    autoload :Square, "pdfrb/annotation/types"
    autoload :Circle, "pdfrb/annotation/types"
    autoload :Line, "pdfrb/annotation/types"
    autoload :Polygon, "pdfrb/annotation/types"
    autoload :Polyline, "pdfrb/annotation/types"
    autoload :Ink, "pdfrb/annotation/types"
    autoload :Widget, "pdfrb/annotation/types"
    autoload :Caret, "pdfrb/annotation/types"
    autoload :Redact, "pdfrb/annotation/types"
    autoload :Watermark, "pdfrb/annotation/types"
    autoload :PrinterMark, "pdfrb/annotation/types"
    autoload :Screen, "pdfrb/annotation/types"
    autoload :Sound, "pdfrb/annotation/types"

    class << self
      def create(subtype, document:, page:, **opts)
        ensure_loaded
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
        ensure_loaded
        registry[subtype]
      end

      def subtypes
        ensure_loaded
        registry.keys
      end

      private

      def ensure_loaded
        return if @loaded

        # Trigger the types.rb load which registers all subtypes.
        Pdfrb::Annotation::Text
        @loaded = true
      end

      def build_fallback(subtype, document, page, opts)
        Base.create(subtype, document: document, page: page, **opts)
      end
    end
  end
end
