# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Metadata stream (s14.3.2, PDF 2.0 App Note 003). XMP payload.
      # Has /Type /Metadata, /Subtype /XML.
      class Metadata < Pdfrb::Model::Cos::Stream
        arlington_object "Metadata"
        register_type :Metadata

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def filter; self[:Filter]; end
        def associated_files; self[:AF]; end

        def xml?
          subtype&.to_sym == :XML
        end

        def xmp?
          return false unless xml? && stream

          data = stream.to_s
          data.include?("<x:xmpmeta") || data.include?("xmlns:x=")
        end

        def xmp_packet?
          return false unless stream

          stream.to_s.include?("<?xpacket")
        end

        def xmp_string
          return nil unless stream

          stream.to_s.force_encoding(Encoding::UTF_8)
        end
      end
    end
  end
end
