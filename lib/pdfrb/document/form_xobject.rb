# frozen_string_literal: true

module Pdfrb
  class Document
    # Form XObject facade. Creates reusable form templates that can
    # be drawn on multiple pages via the /Do operator. A Form XObject
    # is a stream with /Type (omitted), /Subtype /Form, /BBox, and
    # optional /Matrix + /Resources.
    class FormXObject
      attr_reader :document, :stream, :name

      def initialize(document, name: nil, bbox: nil, matrix: nil)
        @document = document
        @bbox = bbox || [0, 0, 612, 792]
        @matrix = matrix

        dict = { Subtype: :Form, BBox: @bbox }
        dict[:Matrix] = @matrix if @matrix
        @stream = document.add(dict, type: Pdfrb::Model::Cos::Stream)
        @name = (name || "Form#{@stream.oid}").to_sym
        @canvas = nil
      end

      # Returns a Canvas for drawing into this Form XObject.
      # The Canvas writes to the Form XObject's content stream.
      def canvas
        return @canvas if @canvas

        contents_stream = @document.add({}, type: Pdfrb::Model::Cos::Stream)
        @stream.value[:Resources] = {}
        @canvas = Pdfrb::Content::Canvas.new(contents_stream, document: @document)
        @stream.stream = +"".b # placeholder; filled by ensure_stream_payload
        @contents_stream = contents_stream
        @canvas
      end

      # Finalize: copy the canvas content into the Form XObject stream
      # and register it in the document's resource names. Called
      # automatically before write.
      def finalize!
        return unless @contents_stream

        @stream.stream = @contents_stream.stream
        @stream.value[:Resources] = @contents_stream.value[:Resources] || {}
      end

      # Register this Form XObject in a page's /Resources /XObject dict
      # so it can be referenced via the /Do operator.
      def register_on_page(page)
        resources = page.value[:Resources]
        resources = {} unless resources.is_a?(::Hash)
        xobjects = resources[:XObject] || {}
        xobjects[@name] = Pdfrb::Model::Reference.new(@stream.oid, @stream.gen)
        resources[:XObject] = xobjects
        page.value[:Resources] = resources
      end

      # Draw this Form XObject on a canvas at the given position.
      def draw_on(target_canvas, at:, scale: 1.0)
        target_canvas.emit_op(Pdfrb::Content::Operator::SaveGraphicsState)
        target_canvas.translate(at[0], at[1])
        target_canvas.scale(scale) if (scale - 1.0).abs > 1e-9
        target_canvas.append(" /#{@name} Do\n")
        target_canvas.emit_op(Pdfrb::Content::Operator::RestoreGraphicsState)
      end
    end
  end
end
