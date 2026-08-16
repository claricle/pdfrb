# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Thread (ISO 32000-2 §12.4.2, PDF 1.1+). Represents an
      # article — a sequence of text blocks that flows across pages
      # (e.g. a newspaper column that continues on a later page).
      # Threads are listed in the Catalog's /Threads array.
      class Thread < Pdfrb::Model::Cos::Dictionary
        arlington_object "Thread"

        # /Type — optional, fixed "Thread".
        def type
          value[:Type]&.to_sym
        end

        # /F — required indirect reference to the first Bead in
        # the thread.
        def first_bead(document = nil)
          ref = value[:F]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /I — optional DocInfo dict with article metadata.
        def info(document = nil)
          ref = value[:I]
          return nil unless ref && document

          resolved = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
          return nil unless resolved

          Pdfrb::Model::Type::Info.new(resolved.value) if resolved.value.is_a?(::Hash)
        end

        # /Metadata — optional indirect stream (PDF 2.0).
        def metadata(document = nil)
          ref = value[:Metadata]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end
      end
    end
  end
end
