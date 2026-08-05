# frozen_string_literal: true

module Pdfrb
  module Encryption
    # Security handler base class. Subclasses implement +decrypt+,
    # +encrypt+, +set_up_decryption+, +set_up_encryption+. Dispatch
    # is via `/Filter` on the trailer's `/Encrypt` dict.
    class SecurityHandler
      attr_reader :document, :encrypt_dict

      def initialize(document)
        @document = document
        @encrypt_dict = nil
      end

      # Dispatch on the trailer's /Encrypt /Filter.
      def self.for(document, decryption_opts: {})
        trailer = document.trailer
        return nil unless trailer

        ref = trailer[:Encrypt]
        return nil unless ref

        encrypt = ref.is_a?(Pdfrb::Model::Reference) ?
                    document.object(ref) : ref
        return nil unless encrypt

        filter = encrypt[:Filter] || :Standard
        klass = registry[filter.to_s] ||
                raise(Pdfrb::EncryptionError, "unsupported /Filter #{filter.inspect}")
        handler = klass.new(document)
        handler.set_up_decryption(**decryption_opts)
        handler
      end

      # Subclasses override.
      def set_up_decryption(**_opts)
        raise NotImplementedError
      end

      def decrypt(_bytes, _oid, _gen)
        raise NotImplementedError
      end

      def encrypt(_bytes, _oid, _gen)
        raise NotImplementedError
      end

      def encrypted?
        !@encrypt_dict.nil?
      end

      class << self
        def registry
          @registry ||= {}
        end

        def register(filter_name, klass)
          registry[filter_name.to_s] = klass
        end

        def lookup(filter_name)
          registry[filter_name.to_s]
        end
      end
    end
  end
end
