# frozen_string_literal: true

require "openssl"
require "stringio"

module Pdfrb
  module DigitalSignature
    module Verification
      module_function

      def verify(pdf_bytes, trusted_certs: [])
        results = []
        offset = 0

        loop do
          sig_info = find_signature(pdf_bytes, offset)
          break unless sig_info

          results << verify_signature(pdf_bytes, sig_info, trusted_certs)
          offset = sig_info[:contents_end] + 1
        end

        results
      end

      def find_signature(pdf_bytes, start_offset)
        contents_marker = "/Contents <"
        ck_start = pdf_bytes.index(contents_marker, start_offset)
        return nil unless ck_start

        hex_start = ck_start + contents_marker.bytesize
        hex_end = pdf_bytes.index(">", hex_start)
        return nil unless hex_end

        br_start = pdf_bytes.rindex("/ByteRange [", ck_start)
        return nil unless br_start

        br_str_start = br_start + "/ByteRange [".bytesize
        br_end = pdf_bytes.index("]", br_str_start)
        return nil unless br_end

        br_str = pdf_bytes[br_str_start...br_end]
        byte_range = br_str.split.map(&:to_i)

        {
          byte_range: byte_range,
          contents_hex_start: hex_start,
          contents_hex_end: hex_end,
          contents_end: hex_end,
        }
      end

      def verify_signature(pdf_bytes, sig_info, trusted_certs)
        byte_range = sig_info[:byte_range]

        if byte_range.nil? || byte_range.length != 4
          return VerificationResult.new(valid?: false,
                                        byte_range_ok?: false,
                                        cert_chain: [],
                                        error: "invalid ByteRange")
        end

        _start1, len1, start2, len2 = byte_range
        part1 = pdf_bytes.bytes[0, len1] || []
        part2 = pdf_bytes.bytes[start2, len2] || []
        signed_data = part1.pack("C*") + part2.pack("C*")

        hex_start = sig_info[:contents_hex_start]
        hex_end = sig_info[:contents_hex_end]
        contents_hex = pdf_bytes[hex_start...hex_end]

        # The /Contents placeholder is zero-padded to its reserved
        # size; DER is self-delimiting, so der_prefix reads the
        # declared length instead of guessing where the signature
        # ends (blindly trimming trailing zeros also eats legitimate
        # 0x00 final bytes and can split a hex byte).
        verify_pkcs7(der_prefix([contents_hex].pack("H*")),
                     signed_data, trusted_certs)
      end

      def verify_pkcs7(der, signed_data, trusted_certs)
        pkcs7 = OpenSSL::PKCS7.new(der)

        store = OpenSSL::X509::Store.new
        trusted_certs.each { |c| store.add_cert(c) }

        valid = pkcs7.verify(nil, store, signed_data,
                             OpenSSL::PKCS7::DETACHED |
                             OpenSSL::PKCS7::BINARY)

        VerificationResult.new(
          signer: pkcs7.signers.first&.issuer&.to_s,
          valid?: valid,
          byte_range_ok?: true,
          cert_chain: pkcs7.certificates || [],
          trusted?: !trusted_certs.empty? && valid,
          error: valid ? nil : "signature verification failed",
        )
      rescue OpenSSL::PKCS7::PKCS7Error, ArgumentError => e
        VerificationResult.new(valid?: false,
                               byte_range_ok?: true,
                               cert_chain: [],
                               error: e.message)
      end

      # The DER structure starting at +bytes+ (a SEQUENCE), exactly
      # as long as its own declared length - any placeholder padding
      # after it is dropped. Non-SEQUENCE input passes through.
      def der_prefix(bytes)
        return bytes if bytes.bytesize < 2 || bytes.getbyte(0) != 0x30

        length = bytes.getbyte(1)
        offset = 2
        if length.anybits?(0x80)
          count = length & 0x7F
          return bytes if count.zero? || bytes.bytesize < 2 + count

          length = 0
          count.times do |i|
            length = (length << 8) | bytes.getbyte(2 + i)
          end
          offset = 2 + count
        end
        bytes.byteslice(0, offset + length)
      end
    end
  end
end
