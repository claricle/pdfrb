# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Trap network annotation (s14.11.5). Marks the extent of the
      # trap network applied by a prepress system. Its appearance
      # stream carries per-colorant trap parameters.
      class TrapNetworkAnnotation < MarkupAnnotation
        arlington_object "AnnotTrapNetwork"

        def last_modified; self[:LastModified]; end
        def version; self[:Version]; end
        def annot_states; self[:AnnotStates]; end
        def font_fauxing; self[:FontFauxing]; end

        def annot_states?
          !annot_states.nil?
        end

        def fauxed_font_names
          fonts = font_fauxing
          fonts.is_a?(Pdfrb::Model::PdfArray) ? fonts.to_a : fonts
        end
      end
    end
  end
end
