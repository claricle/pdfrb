# frozen_string_literal: true

module Pdfrb
  class Document
    # Catalog display controls. Sets viewer behavior: hide toolbar,
    # page layout, page mode, and open-action destination.
    #
    # /ViewerPreferences — fine-grained viewer controls
    # /PageLayout — how pages are laid out in the viewer
    # /PageMode — which panels are visible on open
    # /OpenAction — initial destination or action
    class Display
      PAGE_LAYOUTS = %i[
        SinglePage OneColumn TwoColumnLeft TwoColumnRight
        TwoPageLeft TwoPageRight
      ].freeze

      PAGE_MODES = %i[
        UseNone UseOutlines UseThumbs FullScreen UseOC UseAttachments
      ].freeze

      NON_FULLSCREEN_PAGE_MODES = %i[UseNone UseOutlines UseThumbs UseOC].freeze

      DIRECTIONS = %i[L2R R2L].freeze

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # @param layout [Symbol] one of PAGE_LAYOUTS.
      def page_layout=(layout)
        raise ArgumentError, "invalid page layout: #{layout}" unless PAGE_LAYOUTS.include?(layout)

        document.catalog.value[:PageLayout] = layout
      end

      # @param mode [Symbol] one of PAGE_MODES.
      def page_mode=(mode)
        raise ArgumentError, "invalid page mode: #{mode}" unless PAGE_MODES.include?(mode)

        document.catalog.value[:PageMode] = mode
      end

      # Set the /OpenAction destination or action.
      # @param dest_or_action [Array, Hash, Pdfrb::Destination::Fit,
      #   Pdfrb::Model::PdfArray] the destination array or action dict.
      def open_action=(dest_or_action)
        document.catalog.value[:OpenAction] = dest_or_action
      end

      # Get or set /ViewerPreferences as a keyword-hash.
      def viewer_preferences(**opts)
        return read_viewer_preferences if opts.empty?

        vp = document.catalog.value[:ViewerPreferences]
        vp ||= {}
        opts.each do |key, value|
          vp[key] = value
        end
        document.catalog.value[:ViewerPreferences] = vp
      end

      # Convenience: hide toolbar and menubar, fit window.
      def presentation_mode!
        viewer_preferences(
          HideToolbar: true,
          HideMenubar: true,
          FitWindow: true,
          CenterWindow: true,
          DisplayDocTitle: true
        )
        self.page_mode = :FullScreen
      end

      private

      def read_viewer_preferences
        document.catalog.value[:ViewerPreferences] || {}
      end
    end
  end
end
