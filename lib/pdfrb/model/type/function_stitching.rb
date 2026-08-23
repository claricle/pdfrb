# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 3 Stitching function (s8.9.5). Concatenates multiple
      # sub-functions over a stitched input domain.
      class FunctionStitching < Function
        arlington_object "FunctionType3"
        def sub_functions; self[:Functions]; end
        def bounds; self[:Bounds]; end
        def encode; self[:Encode]; end

        def subfunction_count
          return 0 unless sub_functions

          arr = sub_functions.is_a?(Pdfrb::Model::PdfArray) ? sub_functions.to_a : sub_functions
          arr.is_a?(Array) ? arr.size : 0
        end

        def each_subfunction
          return enum_for(:each_subfunction) unless block_given?
          return unless sub_functions && document

          arr = sub_functions.is_a?(Pdfrb::Model::PdfArray) ? sub_functions.to_a : sub_functions
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end
    end
  end
end
