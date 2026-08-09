# frozen_string_literal: true

require "openssl"
require "net/https"
require "uri"

module Pdfrb
  module DigitalSignature
    # RFC 3161 trusted timestamp client. Submits a hash to a Time
    # Stamp Authority (TSA) over HTTPS and returns the resulting
    # timestamp token (TSTInfo) as DER bytes, suitable for inclusion
    # in a PAdES B-T/LTA signature.
    #
    # Pure-Ruby: uses Net::HTTP with OpenSSL. The TSA URL is
    # configurable; defaults to a free public TSA. Callers in
    # production should configure a trusted TSA endpoint.
    module TimestampClient
      DEFAULT_TSA_URL = "https://freetsa.org/tsr"
      DEFAULT_HASH_ALGORITHM = "sha256"

      module_function

      # Submit +data+ (or its digest) to the TSA at +url+ and return
      # the DER-encoded TimeStampResp.
      #
      # @param data [String] the bytes to timestamp.
      # @param url [String] TSA endpoint URL.
      # @param hash_algorithm [String] OpenSSL digest name.
      # @param cert [OpenSSL::X509::Certificate, nil] client cert.
      # @param key [OpenSSL::PKey::RSA, nil] client key.
      # @return [String] DER-encoded TimeStampResp bytes.
      def request_timestamp(data:, url: DEFAULT_TSA_URL,
                            hash_algorithm: DEFAULT_HASH_ALGORITHM,
                            cert: nil, key: nil)
        digest = OpenSSL::Digest.new(hash_algorithm)
        hashed = digest.digest(data)
        req = build_tsq_request(hashed, hash_algorithm)
        https_post(url, req, cert: cert, key: key)
      end

      DIGEST_OIDS = {
        "sha1" => "1.3.14.3.2.26",
        "sha256" => "2.16.840.1.101.3.4.2.1",
        "sha384" => "2.16.840.1.101.3.4.2.2",
        "sha512" => "2.16.840.1.101.3.4.2.3",
      }.freeze

      # Build the TimeStampReq DER. Pure OpenSSL::ASN1 construction.
      def build_tsq_request(hashed_bytes, hash_algorithm)
        oid = DIGEST_OIDS[hash_algorithm.to_s] || DIGEST_OIDS["sha256"]
        OpenSSL::ASN1::Sequence.new([
                                      OpenSSL::ASN1::Integer.new(1), # version
                                      OpenSSL::ASN1::Sequence.new([ # messageImprint
                                                                    OpenSSL::ASN1::Sequence.new([
                                                                                                  OpenSSL::ASN1::ObjectId.new(oid),
                                                                                                  OpenSSL::ASN1::Null.new(nil),
                                                                                                ]),
                                                                    OpenSSL::ASN1::OctetString.new(hashed_bytes),
                                                                  ]),
                                      OpenSSL::ASN1::Boolean.new(true), # reqCert
                                    ]).to_der
      end

      def https_post(url, body, cert: nil, key: nil)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.is_a?(URI::HTTPS)
        http.ssl_timeout = 30

        if cert && key
          http.cert = cert
          http.key = key
        end

        req = Net::HTTP::Post.new(uri.request_uri)
        req["Content-Type"] = "application/timestamp-query"
        req.body = body

        response = http.request(req)
        raise "TSA error: #{response.code} #{response.message}" unless response.code == "200"

        response.body
      end
    end
  end
end
