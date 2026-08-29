# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Crypt Filter (s7.6.5). Per-stream cipher filter spec — names
      # the cipher and authentication event.
      class CryptFilter < Pdfrb::Model::Cos::Dictionary
        arlington_object "CryptFilter"
        def cipher_method; self[:CFM]&.to_sym; end
        def auth_event; self[:AuthEvent]&.to_sym; end
        def length; self[:Length]; end

        def none?; cipher_method == :None; end
        def v2?; cipher_method == :V2; end
        def aes_v2?; cipher_method == :AESV2; end
        def aes_v3?; cipher_method == :AESV3; end
        def aes_v4?; cipher_method == :AESV4; end

        def open_event?; auth_event == :EFOpen; end
        def doc_open_event?; auth_event == :DocOpen; end

        def has_length?
          length&.positive?
        end
      end

      # Crypt Filter Map (s7.6.5, Table 26). Maps per-page crypt filter
      # names to the default CryptFilter used.
      class CryptFilterMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "CryptFilterMap"
        include NameMap

        alias filter_for []

        def each_filter(&)
          return enum_for(:each_filter) unless block_given?

          value.each(&)
        end
      end

      # Crypt Filter Public Key (s7.6.5, Table 26). Public-key analog
      # of CryptFilter.
      class CryptFilterPublicKey < Pdfrb::Model::Cos::Dictionary
        arlington_object "CryptFilterPublicKey"
        def cipher_method; self[:CFM]&.to_sym; end
        def auth_event; self[:AuthEvent]&.to_sym; end
        def recipients; self[:Recipients]; end
      end

      # Crypt Filter Public Key Map (s7.6.5, Table 26). Maps per-page
      # public-key crypt filters.
      class CryptFilterPublicKeyMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "CryptFilterPublicKeyMap"
        include NameMap

        alias filter_for []
      end
    end
  end
end
