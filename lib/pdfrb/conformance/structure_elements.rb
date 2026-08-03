# frozen_string_literal: true

module Pdfrb
  module Conformance
    # Per-structure-element validation rules derived from the PDF
    # Association's "Tagged PDF Best Practice Guide: Syntax" (BPG).
    #
    # Each standard structure type has expected children and attributes.
    # This module provides a registry of structure-type validators
    # (OCP: add a validator = register, no switch edits).
    module StructureElements
      # Standard PDF structure types (ISO 32000-2 §14.8.4).
      STANDARD_TYPES = %i[
        Document Part Art Sect Div BlockQuote Caption
        TOC TOCI Index NonStruct Private
        H H1 H2 H3 H4 H5 H6
        P L LI Lbl LBody
        Table TR TH TD THead TBody TFoot
        Span Quote Note Reference BibEntry Code
        Figure Formula Form
        Ruby RB RT RP
        Warichu WT WP
        Annot
      ].freeze

      # Map of structure type → expected child types (nil = any).
      EXPECTED_CHILDREN = {
        L: [:LI],
        LI: [:Lbl, :LBody],
        Table: [:THead, :TBody, :TFoot, :TR],
        TR: [:TH, :TD],
        Ruby: [:RB, :RT, :RP],
        Warichu: [:WT, :WP],
        TOC: [:TOCI],
      }.freeze

      # Map of structure type → required attributes (besides /S).
      REQUIRED_ATTRIBUTES = {
        Figure: [:Alt, :ActualText], # at least one required
        Formula: [:Alt, :ActualText], # at least one required
      }.freeze

      class << self
        def standard_types
          STANDARD_TYPES
        end

        def expected_children(type)
          EXPECTED_CHILDREN[type]
        end

        def required_attributes(type)
          REQUIRED_ATTRIBUTES[type]
        end

        def standard?(type)
          STANDARD_TYPES.include?(type.to_sym)
        end
      end
    end
  end
end
