# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Public-key security handler encryption dict (s7.6.5.1).
      class EncryptionPublicKey < Pdfrb::Model::Cos::Dictionary
        arlington_object "EncryptionPublicKey"

        def filter; self[:Filter]; end
        def version; self[:V]; end
        def sub_filter; self[:SubFilter]; end
        def length; self[:Length]; end
        def recipients; self[:Recipients]; end
        def encrypt_metadata?; truthy?(self[:EncryptMetadata]); end

        def public_key?
          filter&.to_sym == :AdobePubSec
        end

        def s2?
          sub_filter&.to_sym == :S2
        end

        def s3?
          sub_filter&.to_sym == :S3
        end

        def s4?
          sub_filter&.to_sym == :S4
        end

        def recipient_count
          return 0 unless recipients

          arr = recipients.is_a?(Pdfrb::Model::PdfArray) ? recipients.to_a : recipients
          arr.is_a?(Array) ? arr.size : 0
        end

        def key_length_bytes
          ((length || 40) / 8)
        end

        def aes?
          (version || 0) >= 4
        end
      end
    end
  end
end
