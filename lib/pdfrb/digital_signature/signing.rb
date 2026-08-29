# frozen_string_literal: true

require "openssl"
require "stringio"

module Pdfrb
  module DigitalSignature
    module Signing
      PLACEHOLDER_HEX_LEN = 8192

      module_function

      def sign(document, cert:, key:, reason: nil, name: nil)
        raise Pdfrb::Error, "OpenSSL cert required" unless cert.is_a?(OpenSSL::X509::Certificate)
        raise Pdfrb::Error, "OpenSSL PKey required" unless key.is_a?(OpenSSL::PKey::PKey)

        sig_dict = build_sig_dict(document, reason: reason, name: name)
        attach_to_acroform(document, sig_dict)

        pdf = serialize(document)
        pdf = insert_contents_placeholder(pdf, sig_dict.oid)
        finalize_signature(pdf, cert, key)
      end

      def build_sig_dict(document, reason:, name:)
        hash = {
          Type: :Sig,
          Filter: :"Adobe.PPKLite",
          SubFilter: :"adbe.pkcs7.detached",
          ByteRange: [0, 0, 0, 0],
        }
        hash[:Reason] = reason if reason
        hash[:Name] = name if name
        hash[:M] = "D:#{Time.now.utc.strftime("%Y%m%d%H%M%S+00'00'")}"
        document.add(hash, type: Pdfrb::Model::Cos::Dictionary)
      end

      def attach_to_acroform(document, sig_dict)
        catalog = document.catalog
        catalog.value[:AcroForm] ||= {}
        catalog.value[:AcroForm][:SigFlags] = 3
        catalog.value[:AcroForm][:Fields] ||= []

        field = document.add(
          { Type: :Annot, Subtype: :Widget, FT: :Sig, T: "Signature1",
            V: sig_dict.ref,
            Rect: [0, 0, 0, 0] },
          type: Pdfrb::Model::Cos::Dictionary
        )
        catalog.value[:AcroForm][:Fields] <<
          field.ref
      end

      def serialize(document)
        io = StringIO.new
        Pdfrb::Writer.write(document, io)
        io.string
      end

      def insert_contents_placeholder(pdf, sig_oid)
        sig_pattern = "#{sig_oid} 0 obj"
        sig_start = pdf.index(sig_pattern)
        return pdf unless sig_start

        dict_end = pdf.index(">>", sig_start)
        return pdf unless dict_end

        placeholder = "0" * PLACEHOLDER_HEX_LEN
        contents_str = "/Contents <#{placeholder}>"

        "#{pdf[0, dict_end + 2]}\n#{contents_str}#{pdf[(dict_end + 2)..]}"
      end

      def finalize_signature(pdf, cert, key)
        marker = "/Contents <"
        contents_marker = pdf.index(marker)
        return pdf unless contents_marker

        hex_start = contents_marker + marker.bytesize
        hex_end = pdf.index(">", hex_start)
        return pdf unless hex_end

        part1_end = hex_start
        part2_start = hex_end + 1
        part2_len = pdf.bytesize - part2_start

        br_old = "/ByteRange [0 0 0 0]"
        br_new = "/ByteRange [0 #{part1_end} #{part2_start} #{part2_len}]"
        size_diff = br_new.bytesize - br_old.bytesize

        if size_diff.positive?
          part1_end += size_diff
          part2_start += size_diff
          br_new = "/ByteRange [0 #{part1_end} #{part2_start} #{part2_len}]"
          new_size_diff = br_new.bytesize - br_old.bytesize
          if new_size_diff != size_diff
            adjust = new_size_diff - size_diff
            part1_end += adjust
            part2_start += adjust
            br_new = "/ByteRange [0 #{part1_end} #{part2_start} #{part2_len}]"
          end
        elsif size_diff.negative?
          br_new = br_new.ljust(br_old.bytesize)
        end

        pdf = pdf.sub(br_old, br_new)

        hex_start = part1_end
        hex_end = pdf.index(">", hex_start)
        hex_len = hex_end - hex_start

        signed_data = pdf.bytes[0, part1_end].pack("C*") +
          pdf.bytes[part2_start, part2_len].pack("C*")

        der = OpenSSL::PKCS7.sign(cert, key, signed_data, [],
                                  OpenSSL::PKCS7::DETACHED |
                                  OpenSSL::PKCS7::BINARY).to_der

        hex_sig = der.unpack1("H*").ljust(hex_len, "0")

        pdf[0, hex_start] + hex_sig + pdf[hex_end..]
      end
    end
  end
end
