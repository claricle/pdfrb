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
      TABLE_CHILDREN = %i[TR THead TBody TFoot].freeze
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

        def validate(document)
          violations = []

          root_ref = document.catalog[:StructTreeRoot]
          return ValidationResult.new(profile: "structure-elements", violations: []) unless root_ref

          root = if root_ref.is_a?(Pdfrb::Model::Reference)
                   document.object(root_ref)
                 else
                   root_ref
                 end
          return ValidationResult.new(profile: "structure-elements", violations: []) unless root

          check_structure(document, root, violations)

          ValidationResult.new(profile: "structure-elements", violations: violations)
        end

        private

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
        def check_structure(document, elem, violations, depth = 0)
          return if depth > 20

          s = elem[:S]
          children = elem[:K]

          if s && !standard?(s)
            role_map = resolve_role_map(document, s)
            unless role_map
              violations << Violation.new(
                rule_id: "ua-9",
                message: "Non-standard structure type #{s} without role mapping",
                object: "StructElem/#{s}",
                severity: :error,
                spec_clause: "ISO 14289-1 7.1"
              )
            end
          end

          if children
            children = Array(children) unless children.is_a?(::Array)
            expected = s ? expected_children(s.to_sym) : nil
            if expected
              children.each do |child_ref|
                child = if child_ref.is_a?(Pdfrb::Model::Reference)
                          document.object(child_ref)
                        else
                          child_ref
                        end
                next unless child

                child_s = child[:S]
                next unless child_s

                if s == :L && child_s != :LI
                  violations << Violation.new(
                    rule_id: "ua-10",
                    message: "List has non-LI child: #{child_s}",
                    object: "StructElem/#{child_s}",
                    severity: :error,
                    spec_clause: "ISO 14289-1 7.2"
                  )
                end

                if s.to_sym == :Table && !TABLE_CHILDREN.include?(child_s.to_sym)
                  violations << Violation.new(
                    rule_id: "ua-11",
                    message: "Table has non-TR child: #{child_s}",
                    object: "StructElem/#{child_s}",
                    severity: :error,
                    spec_clause: "ISO 14289-1 7.2"
                  )
                end

                check_structure(document, child, violations, depth + 1)
              end
            else
              children.each do |child_ref|
                child = if child_ref.is_a?(Pdfrb::Model::Reference)
                          document.object(child_ref)
                        else
                          child_ref
                        end
                next unless child

                check_structure(document, child, violations, depth + 1)
              end
            end
          end
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

        def resolve_role_map(document, type)
          root_ref = document.catalog[:StructTreeRoot]
          return nil unless root_ref

          root = if root_ref.is_a?(Pdfrb::Model::Reference)
                   document.object(root_ref)
                 else
                   root_ref
                 end
          return nil unless root

          rm = root[:RoleMap]
          return nil unless rm

          rm = document.object(rm) if rm.is_a?(Pdfrb::Model::Reference)
          rm&.value&.key?(type.to_sym)
        end
      end
    end
  end
end
