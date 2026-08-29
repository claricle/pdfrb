# frozen_string_literal: true

module Pdfrb
  class Document
    # Annotations facade. Adds and enumerates annotations on pages.
    class Annotations
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def add(page, subtype:, rect:, **opts)
        annot = document.add(
          {
            Type: :Annot,
            Subtype: subtype,
            Rect: rect,
            P: page.ref,
            Contents: opts[:contents],
            F: opts[:flags] || 0
          }.compact,
          type: Pdfrb::Model::Type::Annotation
        )
        annots = (page.value[:Annots] ||= [])
        annots << annot.ref
        annot
      end

      # Sticky-note / comment text annotation.
      def add_text_note(page, rect:, contents:, open: false)
        annot = add(page, subtype: :Text, rect: rect, contents: contents)
        annot.value[:Open] = open unless open == false
        annot
      end

      # Hyperlink annotation pointing at a destination.
      def add_link(page, rect:, dest: nil, uri: nil, highlight: :Invert)
        annot = add(page, subtype: :Link, rect: rect)
        annot.value[:H] = highlight
        if dest
          annot.value[:Dest] = dest
        elsif uri
          action = document.add(
            { Type: :Action, S: :URI, URI: uri },
            type: Pdfrb::Model::Type::Action
          )
          annot.value[:A] = action.ref
        end
        annot
      end

      # Free-text annotation showing inline text on the page.
      def add_free_text(page, rect:, contents:, font: nil, font_size: nil, color: nil)
        annot = document.add(
          {
            Type: :Annot, Subtype: :FreeText, Rect: rect,
            P: page.ref,
            Contents: contents
          },
          type: Pdfrb::Model::Type::FreeTextAnnotation
        )
        da_parts = []
        da_parts << "/#{font} #{font_size} Tf" if font && font_size
        da_parts << "#{color.join(' ')} rg" if color
        annot.value[:DA] = da_parts.join(" ") unless da_parts.empty?
        annots = (page.value[:Annots] ||= [])
        annots << annot.ref
        annot
      end

      # Highlight text-markup annotation over the given quad points.
      def add_highlight(page, quad_points:, contents: nil)
        annot = document.add(
          {
            Type: :Annot, Subtype: :Highlight,
            QuadPoints: quad_points,
            P: page.ref,
            Contents: contents
          }.compact,
          type: Pdfrb::Model::Type::HighlightAnnotation
        )
        annots = (page.value[:Annots] ||= [])
        annots << annot.ref
        annot
      end

      # Stamp annotation (e.g. DRAFT, APPROVED, CONFIDENTIAL).
      def add_stamp(page, rect:, name: :Draft, contents: nil)
        annot = document.add(
          {
            Type: :Annot, Subtype: :Stamp, Rect: rect, Name: name,
            P: page.ref,
            Contents: contents
          }.compact,
          type: Pdfrb::Model::Type::StampAnnotation
        )
        annots = (page.value[:Annots] ||= [])
        annots << annot.ref
        annot
      end

      def count(page)
        annots = page.value[:Annots]
        return 0 unless annots

        annots.is_a?(::Array) ? annots.length : 1
      end

      def each(page, &block)
        return enum_for(:each, page) unless block

        annots = page.value[:Annots]
        return self unless annots

        annots.each do |ref|
          a = document.resolve(ref)
          yield a if a
        end
        self
      end

      # Iterate annotations of a specific subtype across the whole doc.
      def each_of_subtype(subtype, &block)
        return enum_for(:each_of_subtype, subtype) unless block

        document.pages.each do |page|
          each(page) do |annot|
            next unless annot[:Subtype]&.to_sym == subtype

            yield annot
          end
        end
        self
      end

      # Iterate every link annotation in the document.
      def each_link(&block)
        return enum_for(:each_link) unless block

        each_of_subtype(:Link, &block)
      end

      # Iterate every widget (form) annotation in the document.
      def each_widget(&block)
        return enum_for(:each_widget) unless block

        each_of_subtype(:Widget, &block)
      end

      # Iterate every text-markup annotation in the document.
      def each_text_markup(&block)
        return enum_for(:each_text_markup) unless block

        %i[Highlight Underline Squiggly StrikeOut].each do |sub|
          each_of_subtype(sub, &block)
        end
      end
    end
  end
end
