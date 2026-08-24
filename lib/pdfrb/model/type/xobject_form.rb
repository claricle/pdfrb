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

          arr[0] == 1 && arr[1].zero? && arr[2].zero? && arr[3] == 1 && arr[4].zero? && arr[5].zero?
        end
      end

      # PostScript XObject /Subtype /PS (s8.8.2): Level-1 PostScript
      # fallback rendering.
      class XObjectFormPS < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormPS"

        def level1; self[:Level1]; end
      end

      # PostScript passthrough XObject (s8.8.2, PDF 1.3 PS extension
      # /Subtype2 /PS): embedded PS consumed by passthrough printers.
      class XObjectFormPSpassthrough < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormPSpassthrough"

        def level1; self[:Level1]; end
        def postscript; self[:PS]; end
      end

      # Printer's mark form XObject (s14.11.4): registration styles.
      class XObjectFormPrinterMark < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormPrinterMark"

        def mark_style; self[:MarkStyle]; end
        def colorants; self[:Colorants]; end
      end

      # Trap network appearance form XObject (s14.11.2):
      # trapping parameters.
      class XObjectFormTrapNet < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormTrapNet"

        def pcm; self[:PCM]; end
        def separation_color_names; self[:SeparationColorNames]; end
        def trap_regions; self[:TrapRegions]; end
        def trap_styles; self[:TrapStyles]; end
      end

      # Resources /XObject dictionary (s7.8.3): name -> XObject.
      class XObjectMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "XObjectMap"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def add(name, xobject)
          value[name.to_sym] = xobject
          name.to_sym
        end

        def names
          value.keys
        end
      end
    end
  end
end
