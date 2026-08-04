# frozen_string_literal: true

module Pdfrb
  module DigitalSignature
    VerificationResult = Struct.new(
      :signer, :valid?, :byte_range_ok?, :cert_chain, :error,
      :signed_at, :trusted?, keyword_init: true
    ) do
      def trusted?; self[:trusted?]; end
      def has_error?; !error.nil?; end
      def cert_count; cert_chain&.length || 0; end
    end
  end
end
