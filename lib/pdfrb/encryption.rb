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
  end
end
