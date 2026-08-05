# frozen_string_literal: true

require "openssl"
require "digest"

module Pdfrb
  # Encryption layer (s7.6). Security handlers own per-document key
  # derivation and per-object (de)cryption. The Standard handler
  # covers V1..V6 / R2..R6 (RC4 40-bit through AES-256).
  #
  # The Crypt stream filter routes through the active handler; the
  # Serializer accepts an +encrypter+ slot set by the handler.
  module Encryption
    autoload :SecurityHandler, "pdfrb/encryption/security_handler"
    autoload :StandardSecurityHandler, "pdfrb/encryption/standard_security_handler"
    autoload :RC4, "pdfrb/encryption/rc4"
    autoload :AES, "pdfrb/encryption/aes"
    autoload :PasswordVerification, "pdfrb/encryption/password_verification"
    autoload :Identity, "pdfrb/encryption/identity"

    module_function

    # Look up a registered security-handler subclass by /Filter name.
    def handler_for(filter_name)
      SecurityHandler.lookup(filter_name)
    end

    # Build a security handler for +document+ by inspecting its /Encrypt.
    # Returns nil if the document is not encrypted.
    def handler_for_document(document, **opts)
      SecurityHandler.for(document, decryption_opts: opts)
    end
  end
end

# Register built-in handlers after the module is fully defined.
Pdfrb::Encryption::SecurityHandler.register("Standard", Pdfrb::Encryption::StandardSecurityHandler)
