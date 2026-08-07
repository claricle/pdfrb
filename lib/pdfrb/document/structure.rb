# frozen_string_literal: true

module Pdfrb
  class Document
    # Facade for authoring tagged PDF structure trees (PDF/UA §7.9, ISO 32000-2 §14.8).
    #
    # A tagged PDF has:
    #   * /StructTreeRoot on the Catalog — root of the structure hierarchy.
    #   * /MarkInfo /Marked true on the Catalog — declares the PDF as tagged.
    #   * /ParentTree on StructTreeRoot — maps marked-content BDC/EMC
    #     references (via /MCID on BDC) back to their parent StructElem.
    #
    # Structure elements form a tree: a document has sections, sections
    # have headings/paragraphs/figures, etc. Each element has a /S
    # (structure type — :H1, :P, :Figure, :Table, ...) and optional
    # /T (title), /Alt (alternate text), /Lang (language).
    class Structure
      attr_reader :document, :root

      def initialize(document)
        @document = document
        @elements = []
        @current_index = 0
      end

      # Enable tagged PDF: create /StructTreeRoot, set /MarkInfo.
      # Idempotent — returns the existing root if already enabled.
      # @return [Pdfrb::Model::Cos::Dictionary] the StructTreeRoot.
      def enable!
        return @root if @root

        root_elem = document.add(
          { Type: :StructTreeRoot },
          type: Pdfrb::Model::Type::StructTreeRoot
        )
        catalog = document.catalog
        catalog.value[:StructTreeRoot] =
          Pdfrb::Model::Reference.new(root_elem.oid, root_elem.gen)
        mark_info = catalog.value[:MarkInfo]
        if mark_info.nil?
          mark_info = document.add({ Marked: true },
                                   type: Pdfrb::Model::Cos::Dictionary)
          catalog.value[:MarkInfo] =
            Pdfrb::Model::Reference.new(mark_info.oid, mark_info.gen)
        end
        @root = root_elem
      end

      # Add a top-level child element to the structure tree.
      # @param type [Symbol] structure type (:Document, :Part, :H1, :P, ...).
      # @param attrs [Hash] additional attributes (:T, :Alt, :Lang, ...).
      # @return [Pdfrb::Model::Cos::Dictionary] the new element.
      def add_element(type, page: nil, mcid: nil, **attrs)
        ensure_root
        elem = create_element(type, **attrs)
        append_child(@root, elem)

        if page
          page_ref = if page.is_a?(Pdfrb::Model::Reference)
                       page
                     else
                       Pdfrb::Model::Reference.new(page.oid, page.gen)
                     end
          elem.value[:Pg] = page_ref
        end
        elem.value[:K] = { MCID: mcid } if mcid

        @elements << elem
        elem
      end

      # Add a child element to a parent element.
      # @param parent [Pdfrb::Model::Cos::Dictionary] the parent StructElem.
      # @param type [Symbol] structure type.
      # @param attrs [Hash] additional attributes.
      # @return [Pdfrb::Model::Cos::Dictionary] the new element.
      def add_child(parent, type, **attrs)
        elem = create_element(type, **attrs)
        append_child(parent, elem)
        @elements << elem
        elem
      end

      # Set alternate text on a structure element for screen readers.
      # Required for /Figure elements per PDF/UA-1 Tech Note 001.
      # @param element [Pdfrb::Model::Cos::Dictionary] the StructElem.
      # @param text [String] the alt text.
      def set_alt_text(element, text)
        element.value[:Alt] = text.to_s
      end

      # Set actual text on a structure element. Overrides the visual
      # text for screen readers (e.g., expanding abbreviations).
      # @param element [Pdfrb::Model::Cos::Dictionary] the StructElem.
      # @param text [String] the actual text.
      def set_actual_text(element, text)
        element.value[:ActualText] = text.to_s
      end

      # Set language on a structure element (overrides document /Lang).
      # @param element [Pdfrb::Model::Cos::Dictionary] the StructElem.
      # @param lang [String] BCP 47 language tag (e.g., "en-US").
      def set_language(element, lang)
        element.value[:Lang] = lang.to_s
      end

      # Check if a structure element has alt text (required for /Figure).
      # @param element [Pdfrb::Model::Cos::Dictionary] the StructElem.
      # @return [Boolean]
      def has_alt_text?(element)
        alt = element.value[:Alt]
        alt && !alt.to_s.empty?
      end

      # Validate that all /Figure elements have /Alt text per PDF/UA-1.
      # @return [Array<Hash>] list of violations (element + reason).
      def validate_alt_text!
        violations = []
        each_element do |elem|
          next unless elem.value[:S]&.to_sym == :Figure

          unless has_alt_text?(elem)
            violations << { element: elem, reason: "Figure missing /Alt text" }
          end
        end
        violations
      end

      # Walk all structure elements depth-first.
      def each_element(&block)
        return enum_for(:each_element) unless block

        @elements.each(&block)
      end

      # Define a role mapping: maps a custom structure type name to
      # a standard one. Required for PDF/UA when custom types are used.
      # @param custom [Symbol] the custom type name.
      # @param standard [Symbol] the standard type (:H1, :P, :Figure, ...).
      def map_role(custom, standard)
        ensure_root
        role_map = @root.value[:RoleMap]
        if role_map.nil?
          role_map = {}
          @root.value[:RoleMap] = role_map
        end
        role_map[custom] = standard
        role_map
      end

      private

      def build_parent_tree
        return if @root.nil?

        page_map = Hash.new { |h, k| h[k] = [] }
        max_page = -1
        each_element_with_page do |elem, page_index, mcid|
          page_map[page_index] << [mcid, elem]
          max_page = page_index if page_index > max_page
        end

        nums = []
        page_map.keys.sort.each do |page_idx|
          entries = page_map[page_idx]
          nums << page_idx
          nums << entries.length
          entries.each do |_mcid, elem| # rubocop:disable Style/HashEachMethods
            nums << Pdfrb::Model::Reference.new(elem.oid, elem.gen)
          end
        end

        @root.value[:ParentTree] = { Nums: nums }
        @root.value[:ParentTreeNextKey] = max_page + 1 if max_page >= 0
      end

      def each_element_with_page
        return enum_for(:each_element_with_page) unless block_given?

        @elements.each do |elem|
          page_ref = elem.value[:Pg]
          page_index = page_index_for(page_ref)
          mcid = mcid_for(elem)
          yield elem, page_index, mcid
        end
      end

      def page_index_for(page_ref)
        return 0 unless page_ref

        document.pages.each_with_index do |page, idx|
          page_obj = page.is_a?(Pdfrb::Model::Reference) ? document.object(page) : page
          return idx if page_obj == page_ref || page == page_ref
        end
        0
      end

      def mcid_for(elem)
        k = elem.value[:K]
        k.is_a?(::Hash) ? k[:MCID] || 0 : 0
      end

      def ensure_root
        @root || enable!
      end

      def create_element(type, **attrs)
        dict = { Type: :StructElem, S: type }
        dict[:T] = attrs[:title] if attrs[:title]
        dict[:Alt] = attrs[:alt] if attrs[:alt]
        dict[:Lang] = attrs[:lang] if attrs[:lang]
        document.add(dict, type: Pdfrb::Model::Type::StructElem)
      end

      def append_child(parent, child)
        children = parent.value[:K]
        if children.nil?
          parent.value[:K] = [Pdfrb::Model::Reference.new(child.oid, child.gen)]
        elsif children.is_a?(::Array)
          children << Pdfrb::Model::Reference.new(child.oid, child.gen)
        else
          parent.value[:K] = [
            children,
            Pdfrb::Model::Reference.new(child.oid, child.gen),
          ]
        end
        child.value[:P] = Pdfrb::Model::Reference.new(parent.oid, parent.gen)
      end

      public

      # Build the structure tree, ParentTree, and set up /MarkInfo.
      # Idempotent — safe to call multiple times.
      def build!
        enable! if @root.nil?
        return if @elements.empty?

        build_parent_tree
      end
    end
  end
end
