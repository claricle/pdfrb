# frozen_string_literal: true

module Pdfrb
  module Filter
    module BrotliDecode
      module_function

      def decoder(data, **_opts)
        return data unless data

        begin
          require "brotli"
          Brotli.inflate(data)
        rescue LoadError
          raise FilterError, "BrotliDecode requires the 'brotli' gem"
        end
      end

      def encoder(data, **_opts)
        return data unless data

        begin
          require "brotli"
          Brotli.deflate(data)
        rescue LoadError
          data
        end
      end
    end
    REGISTRY[:BrotliDecode] = BrotliDecode if defined?(REGISTRY)
  end
end
