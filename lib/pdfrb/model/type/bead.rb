# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Bead (ISO 32000-2 §12.4.3, PDF 1.1+). A single rectangular
      # portion of a page that is part of a Thread (article). Beads
      # form a doubly-linked list via /N (next) and /V (previous).
      class Bead < Pdfrb::Model::Cos::Dictionary
        arlington_object "Bead"

        # /Type — optional, fixed "Bead".
        def type
          value[:Type]&.to_sym
        end

        # /T — optional indirect Thread this bead belongs to.
        def thread(document = nil)
          ref = value[:T]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /N — required indirect next Bead.
        def next_bead(document = nil)
          ref = value[:N]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /V — required indirect previous Bead.
        def previous_bead(document = nil)
          ref = value[:V]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /P — required indirect Page the bead sits on.
        def page(document = nil)
          ref = value[:P]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /R — required rectangle on the page.
        def rect
          value[:R]
        end
      end

      # First-bead variant (s7.10.2): the bead that starts a thread;
      # carries the thread /T reference.
      class BeadFirst < Bead
        arlington_object "BeadFirst"

        def thread; self[:T]; end
      end
    end
  end
end
