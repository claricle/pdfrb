# frozen_string_literal: true

module Pdfrb
  module Annotation
    # Base annotation builder. Subclasses override +subtype+ and
    # +default_fields+ to provide type-specific defaults. Each subclass
    # calls +register_as+ at load time.
    class Base
      class << self
        # @return [Symbol] the /Subtype value (e.g. :Link).
        def subtype
          raise NotImplementedError, "#{self} must define subtype"
        end

        # Extra fields to merge into the annotation dict.
        # @return [Hash]
        def default_fields
          {}
        end

        # Create the annotation and attach it to the page's /Annots.
        def create(document:, page:, rect:, **opts)
          dict = base_dict(page: page, rect: rect, **opts).merge!(default_fields).merge!(type_overrides(opts))
          annot = document.add(dict, type: Pdfrb::Model::Type::Annotation)
          attach_to_page(page, annot)
          annot
        end

        # Register this class in the Annotation registry.
        def register_as(symbol = subtype)
          Annotation.register(symbol, self)
          self
        end

        private

        def base_dict(page:, rect:, contents: nil, flags: 0, **)
          {
            Type: :Annot,
            Subtype: subtype,
            Rect: rect,
            P: page.ref,
            Contents: contents,
            F: flags,
          }.compact
        end

        def type_overrides(opts)
          overrides = {}
          overrides[:C] = opts[:color] if opts.key?(:color)
          overrides[:Border] = opts[:border] if opts.key?(:border)
          overrides[:A] = opts[:action] if opts.key?(:action)
          overrides[:Dest] = opts[:dest] if opts.key?(:dest)
          overrides[:H] = opts[:highlight] if opts.key?(:highlight)
          overrides[:BS] = opts[:border_style] if opts.key?(:border_style)
          overrides[:QuadPoints] = opts[:quad_points] if opts.key?(:quad_points)
          overrides[:T] = opts[:title] if opts.key?(:title)
          overrides[:RC] = opts[:rich_contents] if opts.key?(:rich_contents)
          overrides[:CreationDate] = opts[:created_at] if opts.key?(:created_at)
          overrides[:M] = opts[:modified_at] if opts.key?(:modified_at)
          overrides[:NM] = opts[:name] if opts.key?(:name)
          overrides.compact
        end

        def attach_to_page(page, annot)
          annots = page.value[:Annots]
          ref = annot.ref
          if annots.nil?
            page.value[:Annots] = [ref]
          elsif annots.is_a?(::Array)
            annots << ref
          else
            page.value[:Annots] = [annots, ref]
          end
        end
      end
    end
  end
end
