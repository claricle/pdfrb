# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class DocumentSecurityStore < Cos::Dictionary
        register_type :DSS

        def certs; self[:Certs]; end
        def ocsp; self[:OCSPs]; end
        def crl; self[:CRLs]; end
      end
    end
  end
end
