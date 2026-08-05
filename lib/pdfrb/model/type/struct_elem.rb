# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure element (s14.7.4). One node in the structure tree.
      # Holds /S (structure type), /P (parent), /K (kids), /Pg,
      # /A, /C. Per PDF/UA Tech Note 001, /ActualText may appear
      # for /Figure elements.
      class StructElem < Pdfrb::Model::Cos::Dictionary
        arlington_object "StructElem"
        register_type :StructElem

        def type; self[:Type]; end
        def structure_type; self[:S]; end
        def parent; self[:P]; end
        def kids; self[:K]; end
        def page; self[:Pg]; end
        def attributes; self[:A]; end
        def classes; self[:C]; end
        def actual_text; self[:ActualText]; end
        def alt_text; self[:Alt]; end
        def title; self[:T]; end
        def lang; self[:Lang]; end
        def expanded_abbreviation; self[:E]; end

        def block_level?
          %i[Document Part Art Sect Div BlockQuote Caption TOC TOCI
             Index NonStruct H H1 H2 H3 H4 H5 H6 P L LI Lbl LBody
             Table TR TH TD THead TBody TFoot].include?(structure_type&.to_sym)
        end

        def inline_level?
          %i[Span Quote Note Reference BibEntry Code Figure Formula Form].include?(structure_type&.to_sym)
        end

        def has_alt_text?
          !!alt_text
        end

        def has_actual_text?
          !!actual_text
        end

        def figure?
          structure_type&.to_sym == :Figure
        end

        def link?
          structure_type&.to_sym == :Link
        end

        def heading?
          %i[H H1 H2 H3 H4 H5 H6].include?(structure_type&.to_sym)
        end

        def table?
          structure_type&.to_sym == :Table
        end

        def resolved_parent
          ref = parent
          return nil unless ref && document

          document.object(ref)
        end

        def resolved_page
          ref = page
          return nil unless ref && document

          document.object(ref)
        end

        def each_child
          return enum_for(:each_child) unless block_given?
          return unless kids && document

          arr = kids.is_a?(Pdfrb::Model::Reference) ? document.object(kids) : kids
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |kid|
            obj = kid.is_a?(Pdfrb::Model::Reference) ? document.object(kid) : kid
            yield obj if obj
          end
        end
      end
    end
  end
end
