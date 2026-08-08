# frozen_string_literal: true

module Pdfrb
  module Filter
    # Crypt filter (s7.4.16). Routes through the document's security
    # handler when the document is encrypted; pass-through when not.
    # The `/Identity` name means "no decryption".
    class Crypt
      include Base

      register_as "Crypt"

      class << self
        def decoder(bytes, parms, document)
          return bytes unless document
          return bytes if parms == :Identity || parms.nil?

          handler = document.security_handler if !document.config["security.handler"].nil?
          return bytes unless handler

          handler.decrypt(bytes, document.current_object_oid)
        end

        def encoder(bytes, parms, document)
          return bytes unless document
          return bytes if parms == :Identity || parms.nil?

          handler = document.security_handler if !document.config["security.handler"].nil?
          return bytes unless handler

          handler.encrypt(bytes, document.current_object_oid)
        end
      end
    end
  end
end
