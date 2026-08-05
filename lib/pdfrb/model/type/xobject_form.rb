# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Form XObject (s8.10). /Type /XObject, /Subtype /Form,
      # /BBox, /Matrix, /Resources, /Group, /Filter, etc.
      class XObjectForm < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormType1"

        def subtype; self[:Subtype]; end
        def bbox; self[:BBox]; end
        def matrix; self[:Matrix]; end
        def resources; self[:Resources]; end
        def group; self[:Group]; end
        def filter; self[:Filter]; end
        def decode_parms; self[:DecodeParms]; end
        def form_type; self[:FormType] || 1; end
        def oc; self[:OC]; end
        def name; self[:Name]; end
        def last_modified; self[:LastModified]; end
        def piece_info; self[:PieceInfo]; end
        def struct_parent; self[:StructParent]; end
        def associated_files; self[:AF]; end
        def mark_stream_data?; truthy?(self[:MS]); end

        def transparency_group?
          !!group
        end

        def isolated?
          group && !!group[:I]
        end

        def knockout?
          group && !!group[:K]
        end

        def default_color_space
          group && group[:CS]
        end

        def identity_matrix?
          return true unless matrix
          arr = matrix.is_a?(Pdfrb::Model::PdfArray) ? matrix.to_a : matrix
          return true unless arr.is_a?(Array) && arr.size == 6
          arr[0] == 1 && arr[1] == 0 && arr[2] == 0 && arr[3] == 1 && arr[4] == 0 && arr[5] == 0
        end
      end
    end
  end
end
