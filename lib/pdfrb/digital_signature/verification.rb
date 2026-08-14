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
        contents_hex = contents_hex.sub(/0+$/, "")

        begin
          der = [contents_hex].pack("H*")
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
      end
    end
  end
end
