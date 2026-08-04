# frozen_string_literal: true

module Pdfrb
  module DigitalSignature
    module TimestampHandler
      module_function

      def type; :"adbe.revision"; end

      def create_timestamp(data, tsa_url: nil)
        return nil unless tsa_url

        require "net/http"
        require "uri"

        uri = URI(tsa_url)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new(uri.request_uri)
          req["Content-Type"] = "application/timestamp-query"
          req.body = build_tsr_request(data)
          http.request(req)
        end

        response.body if response.is_a?(Net::HTTPSuccess)
      end

      def build_tsr_request(data)
        require "openssl"
        hash = OpenSSL::Digest.new("SHA256")
        req = OpenSSL::ASN1::Sequence.new([
                                            OpenSSL::ASN1::Integer.new(1),
                                            OpenSSL::ASN1::Sequence.new([
                                                                          OpenSSL::ASN1::Sequence.new([
                                                                                                        OpenSSL::ASN1::ObjectId.new("2.16.840.1.101.3.4.2.1"),
                                                                                                        OpenSSL::ASN1::OctetString.new(hash.digest(data).force_encoding("BINARY")),
                                                                                                      ]),
                                                                        ]),
                                            OpenSSL::ASN1::Integer.new(0),
                                            OpenSSL::ASN1::Boolean.new(false),
                                          ])
        req.to_der
      end
    end
  end
end
