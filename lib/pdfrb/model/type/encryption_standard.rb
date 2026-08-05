# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Standard security handler encryption dict (s7.6.3.4).
      class EncryptionStandard < Pdfrb::Model::Cos::Dictionary
        arlington_object "EncryptionStandard"

        def filter; self[:Filter]; end
        def sub_filter; self[:SubFilter]; end
        def version; self[:V]; end
        def revision; self[:R]; end
        def length; self[:Length]; end
        def permissions; self[:P]; end
        def owner_password; self[:O]; end
        def user_password; self[:U]; end
        def encrypt_metadata?; self[:EncryptMetadata]; end
        def recipient_info; self[:Recipients]; end

        def key_length_bytes
          ((length || 40) / 8)
        end

        def aes?
          (version || 0) >= 4
        end

        def rc4?
          (version || 0) < 4
        end

        def public_key?
          filter&.to_sym == :AdobePubSec
        end

        def standard?
          filter&.to_sym == :Standard
        end

        def metadata_encrypted?
          encrypt_metadata.nil? ? true : !!encrypt_metadata
        end

        def allow_print?
          permissions && (permissions & 4) != 0
        end

        def allow_modify_contents?
          permissions && (permissions & 8) != 0
        end

        def allow_copy?
          permissions && (permissions & 16) != 0
        end

        def allow_annotations?
          permissions && (permissions & 32) != 0
        end

        def allow_fill_in?
          permissions && (permissions & 256) != 0
        end

        def allow_extract?
          permissions && (permissions & 512) != 0
        end

        def allow_assemble?
          permissions && (permissions & 1024) != 0
        end

        def allow_print_high_res?
          permissions && (permissions & 2048) != 0
        end
      end
    end
  end
end
