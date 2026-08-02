# frozen_string_literal: true

module Pdfrb
  class Document
    # Font facade. +add+ registers a font in the catalog /Resources
    # (so the canvas can reference it via +Tf+) and returns the
    # resource name to use with the canvas.
    #
    # Supports the 14 PDF standard Type1 fonts by name (Helvetica,
    # Times-Roman, Courier, etc.) without embedding. Future TTF/OTF
    # loaders (TODO 111/112) plug in via +register_loader+.
    class Fonts
      STANDARDS = %w[
        Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
        Times-Roman Times-Bold Times-Italic Times-BoldItalic
        Courier Courier-Bold Courier-Oblique Courier-BoldOblique
        Symbol ZapfDingbats
      ].freeze

      attr_reader :document

      def initialize(document)
        @document = document
        @next_id = 1
        @registry = {} # name -> resource Symbol
      end

      # Register a font and return the resource name (e.g. :F1).
      #
      # For the 14 standard fonts: pass the font name; no embedding
      # is required. For everything else, use the loader protocol
      # (TODO 111).
      def add(name_or_io, **opts)
        name = font_name_for(name_or_io)
        cached = @registry[name]
        return cached if cached

        resource = next_resource_name
        register_font(resource, name, **opts)
        @registry[name] = resource
        resource
      end

      # Look up the resource name registered for a font name.
      def [](name)
        @registry[name]
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        @registry.each(&block)
        self
      end

      # ---- Extension point (TODOs 110-112) ----
      #
      # A loader is an object with `call(document, name_or_io, **opts)`
      # that returns a Font dict + descriptor pair. Built-in loader
      # handles the 14 standards; future loaders add TTF/OTF/CID.
      class << self
        def loaders
          @loaders ||= []
        end

        def register_loader(loader)
          loaders.unshift(loader)
        end
      end

      register_loader ->(doc, name, **opts) {
        next nil unless STANDARDS.include?(name.to_s)
        next nil unless opts[:embedded].nil? # standards never embed

        doc.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
      }

      private

      def font_name_for(name_or_io)
        case name_or_io
        when Symbol, String then name_or_io.to_s
        else
          raise ArgumentError,
                "font name must be a String or Symbol; TTF/OTF IO loading lands in TODO 111"
        end
      end

      def next_resource_name
        sym = :"F#{@next_id}"
        @next_id += 1
        sym
      end

      def register_font(resource, name, **opts)
        loader = self.class.loaders.find { |l| l.call(document, name, **opts) }
        font_dict = loader ? loader.call(document, name, **opts) :
                     default_font(name)
        attach_to_resources(resource, font_dict)
      end

      def default_font(name)
        document.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
      end

      def attach_to_resources(resource, font_dict)
        ref = Pdfrb::Model::Reference.new(font_dict.oid, font_dict.gen)
        catalog = document.catalog
        catalog.value[:Resources] ||= {}
        catalog.value[:Resources][:Font] ||= {}
        catalog.value[:Resources][:Font][resource] = ref
      end
    end
  end
end
