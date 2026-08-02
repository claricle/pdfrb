# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Annotation base class (s12.5). The base dict shape is encoded
      # across the per-subtype TSVs (AnnotLink, AnnotText, ...), not
      # a single Annot.tsv — so the base class registers in the
      # type_map and dispatches to a specific subtype class via
      # /Subtype lookup.
      class Annotation < Pdfrb::Model::Cos::Dictionary
        # Common annotation fields per s12.5.2 (hand-coded; base dict
        # is shared across all subtypes before subtype-specific keys).
        define_field :Type, type: Symbol, default: :Annot
        define_field :Subtype, type: Symbol, required: true
        define_field :Rect, type: Pdfrb::Model::Rectangle
        define_field :Contents, type: String
        define_field :P, type: Pdfrb::Model::Cos::Dictionary, indirect: true
        define_field :NM, type: String
        define_field :M, type: Pdfrb::Model::Cos::Fields::PDFDate
        define_field :F, type: Integer
        define_field :AP, type: Pdfrb::Model::Cos::Dictionary
        define_field :AS, type: Symbol
        define_field :Border, type: Pdfrb::Model::PdfArray
        define_field :C, type: Pdfrb::Model::PdfArray
        define_field :A, type: Pdfrb::Model::Cos::Dictionary
        define_field :AA, type: Pdfrb::Model::Cos::Dictionary

        register_type :Annot

        class << self
          # Dispatch by /Subtype. Subclasses register via
          # `register_subtype :Link`.
          def subtype_map
            @subtype_map ||= {}
          end

          def register_subtype(symbol, klass = self)
            subtype_map[symbol] = klass
          end

          def for_subtype(symbol)
            subtype_map[symbol]
          end
        end
      end
    end
  end
end

