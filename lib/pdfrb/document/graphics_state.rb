# frozen_string_literal: true

module Pdfrb
  class Document
    # Facade for managing ExtGState (graphics state) entries on pages.
    # Each page can reference a /ExtGState sub-dict in /Resources that
    # holds named graphics-state parameter sets (transparency, line
    # width, overprint, etc.).
    class GraphicsState
      attr_reader :document

      def initialize(document)
        @document = document
        @next_gs_number = 1
      end

      # Register an ExtGState parameter dict on a page and return the
      # resource name (e.g., :GS1).
      #
      # @param page [Pdfrb::Model::Type::Page] target page.
      # @param params [Hash] graphics state parameters (e.g.,
      #   { CA: 0.5, ca: 0.5 } for 50% stroke + fill alpha).
      # @return [Symbol] resource name.
      def register(page, **params)
        gs = document.add({ Type: :ExtGState, **params },
                          type: Pdfrb::Model::Type::GraphicsStateParameter)
        ref = Pdfrb::Model::Reference.new(gs.oid, gs.gen)

        resources = ensure_resources(page)
        ext_gstate = resources.value[:ExtGState] || {}
        name = gs_name
        ext_gstate[name] = ref
        resources.value[:ExtGState] = ext_gstate
        name
      end

      # Convenience: register a transparency state.
      def register_transparency(page, opacity:, blend_mode: nil)
        params = { ca: opacity, CA: opacity }
        params[:BM] = blend_mode if blend_mode
        register(page, **params)
      end

      # Convenience: register a line-width state.
      def register_line_width(page, width:, line_cap: nil, line_join: nil)
        params = { LW: width }
        params[:LC] = line_cap if line_cap
        params[:LJ] = line_join if line_join
        register(page, **params)
      end

      # Enumerate ExtGState entries on a page.
      def each(page, &block)
        return enum_for(:each, page) unless block

        resources = page_resources(page)
        return unless resources

        ext = resources.value[:ExtGState]
        return unless ext

        ext.each(&block)
      end

      def count(page)
        each(page).count
      end

      private

      def ensure_resources(page)
        resources = page.value[:Resources]
        return resources if resources.is_a?(Pdfrb::Model::Cos::Dictionary)

        wrapped = Pdfrb::Model::Cos::Dictionary.new(resources || {})
        page.value[:Resources] = wrapped
        wrapped
      end

      def page_resources(page)
        page.value[:Resources]
      end

      def gs_name
        name = :"GS#{@next_gs_number}"
        @next_gs_number += 1
        name
      end
    end
  end
end
