# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Document Security Store (s12.8.4.3, PDF 2.0). Holds certs, CRLs,
      # and OCSP responses used by signature verification.
      class DocumentSecurityStore < Cos::Dictionary
        register_type :DSS

        def type; self[:Type]; end
        def certs; self[:Certs]; end
        def ocsp; self[:OCSPs]; end
        def crl; self[:CRLs]; end
        def vri; self[:VRI]; end

        def cert_count
          return 0 unless certs

          arr = certs.is_a?(Pdfrb::Model::PdfArray) ? certs.to_a : certs
          arr.is_a?(Array) ? arr.size : 0
        end

        def ocsp_count
          return 0 unless ocsp

          arr = ocsp.is_a?(Pdfrb::Model::PdfArray) ? ocsp.to_a : ocsp
          arr.is_a?(Array) ? arr.size : 0
        end

        def crl_count
          return 0 unless crl

          arr = crl.is_a?(Pdfrb::Model::PdfArray) ? crl.to_a : crl
          arr.is_a?(Array) ? arr.size : 0
        end

        def has_vri?
          !!vri
        end

        def each_cert
          return enum_for(:each_cert) unless block_given?
          return unless certs && document

          arr = certs.is_a?(Pdfrb::Model::PdfArray) ? certs.to_a : certs
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end
    end
  end
end
