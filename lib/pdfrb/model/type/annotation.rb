# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Annotation < Pdfrb::Model::Cos::Dictionary
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
        define_field :StructParent, type: Integer
        define_field :OC, type: Pdfrb::Model::Cos::Dictionary

        register_type :Annot

        # ---- Accessors ----
        def subtype; self[:Subtype]; end
        def rect; self[:Rect]; end
        def contents; self[:Contents]; end
        def name; self[:NM]; end
        def modified_date; self[:M]; end
        def flags; self[:F] || 0; end
        def color; self[:C]; end
        def border; self[:Border]; end
        def appearance; self[:AP]; end
        def appearance_state; self[:AS]; end
        def action; self[:A]; end
        def additional_actions; self[:AA]; end

        # ---- Page reference ----
        def page
          ref = self[:P]
          return nil unless ref && document

          document.object(ref)
        end

        # ---- Flag predicates ----
        def hidden?; flags & 1 != 0; end
        def print?; flags & 2 != 0; end
        def no_zoom?; flags & 4 != 0; end
        def no_rotate?; flags & 8 != 0; end
        def no_view?; flags & 16 != 0; end
        def read_only?; flags & 32 != 0; end
        def locked?; flags & 128 != 0; end
        def toggle_no_view?; flags & 256 != 0; end
        def locked_contents?; flags & 512 != 0; end

        # ---- Appearance management ----
        def normal_appearance
          ap = appearance
          return nil unless ap

          ap = document.object(ap) if ap.is_a?(Pdfrb::Model::Reference) && document
          ap && ap[:N]
        end

        def create_appearance_stream
          AppearanceGenerator.for(self, document: document)&.create_appearance
        end

        # ---- Subtype dispatch ----
        class << self
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
