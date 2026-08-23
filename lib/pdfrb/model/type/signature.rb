# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Signature dictionary (s12.8.2). Carries the PKCS#7 / CMS
      # signature payload. Lives in a Signature field's /V entry.
      class Signature < Pdfrb::Model::Cos::Dictionary
        arlington_object "Signature"
        def type; self[:Type]; end
        def filter; self[:Filter]; end
        def sub_filter; self[:SubFilter]; end
        def contents; self[:Contents]; end
        def cert; self[:Cert]; end
        def byte_range; self[:ByteRange]; end
        def reference; self[:Reference]; end
        def changes; self[:Changes]; end
        def name; self[:Name]; end
        def reason; self[:Reason]; end
        def location; self[:Location]; end
        def contact_info; self[:ContactInfo]; end
        def m; self[:M]; end
        def prop_build; self[:Prop_Build]; end
        def prop_auth_time; self[:Prop_AuthTime]; end
        def prop_auth_type; self[:Prop_AuthType]; end

        def signed_time
          return nil unless m

          m.is_a?(Time) ? m : parse_pdf_date(m)
        end

        def pkcs7_detached?
          sub_filter == :"adbe.pkcs7.detached"
        end

        def pkcs7_sha1?
          sub_filter == :"adbe.pkcs7.sha1"
        end

        def pkcs1?
          sub_filter == :"adbe.x509.rsa_sha1"
        end

        def has_byte_range?
          range = byte_range
          range = range.to_a if range.is_a?(Pdfrb::Model::PdfArray)
          range.is_a?(::Array) && range.size == 4
        end

        private

        def parse_pdf_date(str)
          return nil unless str

          match = str.to_s.match(/^D:(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?/)
          return nil unless match

          Time.new(match[1].to_i, match[2].to_i, match[3].to_i,
                   (match[4] || 0).to_i, (match[5] || 0).to_i, (match[6] || 0).to_i,
                   "+00:00")
        rescue StandardError
          nil
        end
      end
    end
  end
end
