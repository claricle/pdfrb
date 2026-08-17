# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DPartRoot (ISO 16612-2 PDF/VT §6.3.4). The root of the
      # Document Part hierarchy, attached to the Catalog via the
      # /DPartRoot key. Represents the root node of a tree whose
      # leaves are groups of document parts.
      class DPartRoot < Pdfrb::Model::Cos::Dictionary
        arlington_object "DPartRoot"

        # /Type — optional, fixed "DPartRoot".
        def type
          value[:Type]&.to_sym
        end

        # /DPartRootNode — required indirect reference to the
        # first DPart child.
        def root_node(document = nil)
          ref = value[:DPartRootNode]
          return nil unless ref && document

          resolved = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
          return nil unless resolved && resolved.value.is_a?(::Hash)

          DPart.new(resolved.value)
        end

        # /RecordLevel — optional integer >= 0, the nesting depth
        # at which DParts represent individual records.
        def record_level
          value[:RecordLevel]
        end

        # /NodeNameList — optional array of names identifying the
        # tree levels (required for PDF/VT-2).
        def node_name_list
          value[:NodeNameList]
        end
      end

      # DPart (ISO 16612-2 PDF/VT §6.3.5). One node in the Document
      # Part hierarchy. Either has /DParts (a tree of child DParts)
      # or /Start + /End pointing to the page range it covers.
      class DPart < Pdfrb::Model::Cos::Dictionary
        arlington_object "DPart"

        # /Type — optional, fixed "DPart".
        def type
          value[:Type]&.to_sym
        end

        # /Parent — required indirect ref to the containing DPart
        # or DPartRoot (may be absent when Metadata is present).
        def parent(document = nil)
          ref = value[:Parent]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /DParts — array of arrays of child DParts. Mutually
        # exclusive with /Start + /End.
        def child_parts
          value[:DParts]
        end

        # /Start — indirect ref to the first Page in this part.
        def start_page(document = nil)
          ref = value[:Start]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /End — indirect ref to the last Page in this part.
        def end_page(document = nil)
          ref = value[:End]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        def leaf?
          child_parts.nil?
        end
      end
    end
  end
end
