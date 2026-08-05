# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Cross-reference stream (s7.5.8, PDF 1.5+). Doubles as the
      # trailer dict in PDF 1.5+ documents.
      class XRefStream < Pdfrb::Model::Cos::Stream
        arlington_object "XRefStream"
        register_type :XRef

        def type; self[:Type]; end
        def size; self[:Size]; end
        def prev; self[:Prev]; end
        def root; self[:Root]; end
        def encrypt; self[:Encrypt]; end
        def info; self[:Info]; end
        def id; self[:ID]; end
        def w; self[:W]; end
        def index; self[:Index]; end
        def filter; self[:Filter]; end

        def encrypted?
          !!encrypt
        end

        def incremental?
          !!prev
        end

        def field_widths
          return [0, 0, 0] unless w

          arr = w.is_a?(Pdfrb::Model::PdfArray) ? w.to_a : w
          return [0, 0, 0] unless arr.is_a?(Array) && arr.size == 3

          arr
        end

        def subsection_index
          return [[0, size || 0]] unless index

          arr = index.is_a?(Pdfrb::Model::PdfArray) ? index.to_a : index
          return [[0, size || 0]] unless arr.is_a?(Array)

          arr.each_slice(2).to_a
        end
      end
    end
  end
end
