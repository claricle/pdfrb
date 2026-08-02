# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Public-key security handler encryption dict (s7.6.5.1).
      class EncryptionPublicKey < Pdfrb::Model::Cos::Dictionary
        arlington_object "EncryptionPublicKey"
      end
    end
  end
end
