# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Ink annotation (s12.5.6.13). Freehand scribble path(s).
      class InkAnnotation < MarkupAnnotation
        arlington_object "AnnotInk"
        def ink_list; self[:InkList]; end
        def interior_color; self[:IC]; end
        def border_style; self[:BS]; end
        def border; self[:Border]; end

        def path_count
          return 0 unless ink_list

          arr = ink_list.is_a?(Pdfrb::Model::PdfArray) ? ink_list.to_a : ink_list
          arr.is_a?(Array) ? arr.size : 0
        end

        def path_at(index)
          return nil unless ink_list

          arr = ink_list.is_a?(Pdfrb::Model::PdfArray) ? ink_list.to_a : ink_list
          arr && arr[index]
        end
      end
    end
  end
end
