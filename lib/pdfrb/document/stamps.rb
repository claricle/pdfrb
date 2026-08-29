# frozen_string_literal: true

module Pdfrb
  class Document
    # Page stamping facade. Stamps a Form XObject (logo, watermark,
    # page number) onto every page of the document by emitting the
    # Do operator in each page's content stream.
    class Stamps
      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Stamp a Form XObject on every page.
      #
      # @param form_xobject [Pdfrb::Model::Cos::Stream] the Form XObject.
      # @param at [Array<Numeric>] x, y position in points.
      # @return [Symbol] the resource name (e.g., :St1).
      def stamp_everywhere(form_xobject, at: [0, 0])
        name = next_stamp_name
        ref = form_xobject.ref

        document.pages.each do |page|
          register_xobject_in_resources(page, name, ref)
          emit_do_operator(page, name, at)
        end
        name
      end

      # Stamp a Form XObject on a single page.
      def stamp_page(page, form_xobject, at: [0, 0])
        name = next_stamp_name
        ref = form_xobject.ref
        register_xobject_in_resources(page, name, ref)
        emit_do_operator(page, name, at)
        name
      end

      private

      def next_stamp_name
        @stamp_counter ||= 0
        @stamp_counter += 1
        :"St#{@stamp_counter}"
      end

      def register_xobject_in_resources(page, name, ref)
        resources = page.value[:Resources]
        resources = page.value[:Resources] = {} unless resources.is_a?(Pdfrb::Model::Cos::Dictionary)
        xobjects = resources.value[:XObject] || {}
        xobjects[name] = ref
        resources.value[:XObject] = xobjects
      end

      def emit_do_operator(page, name, at)
        canvas = page.canvas
        x, y = at
        canvas.save_graphics_state
        canvas.translate(x, y) if x != 0 || y != 0
        canvas.emit_op(Pdfrb::Content::Operator::InvokeXObject, name)
        canvas.restore_graphics_state
      rescue StandardError
        # Canvas may not be available on pages with no content stream yet.
      end
    end
  end
end
