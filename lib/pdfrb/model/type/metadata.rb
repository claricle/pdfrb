# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Metadata stream (s14.3.2, PDF 2.0 App Note 003). XMP payload.
      # Has /Type /Metadata, /Subtype /XML.
      class Metadata < Pdfrb::Model::Cos::Stream
        arlington_object "Metadata"
        register_type :Metadata

        # Per PDF 2.0 App Note 003, /Metadata must NOT appear on
        # Document Part Metadata (DPM) dicts. Validate callers don't
        # try to attach one there.
      end
    end
  end
end
