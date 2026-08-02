# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Root of the document object hierarchy (s7.7.2). Linked from
      # the trailer's /Root. Fields: /Type, /Version, /Extensions,
      # /Pages, /PageLabels, /Names, /Dests, /ViewerPreferences,
      # /PageLayout, /PageMode, /Outlines, /Threads, /OpenAction,
      # /AA, /URI, /AcroForm, /Metadata, /StructTreeRoot, /MarkInfo,
      # /Lang, /SpiderInfo, /OutputIntents, /PieceInfo, /OCProperties,
      # /Perms, /Legal, /Requirements, /Collection, /NeedsRendering,
      # /DSS, /AF, /DPartRoot.
      class Catalog < Pdfrb::Model::Cos::Dictionary
        arlington_object "Catalog"
        register_type :Catalog

        # Returns the /Pages tree root, auto-resolving the reference.
        def pages
          self[:Pages]
        end

        # Returns the /AcroForm dict (or nil).
        def acro_form
          self[:AcroForm]
        end

        def outlines
          self[:Outlines]
        end

        def names
          self[:Names]
        end

        def metadata
          self[:Metadata]
        end

        def struct_tree_root
          self[:StructTreeRoot]
        end

        def open_action
          self[:OpenAction]
        end
      end
    end
  end
end
