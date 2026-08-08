# frozen_string_literal: true

module Pdfrb
  # Stream filter pipeline (s7.4). Each filter is a stateless class
  # with `decoder(bytes, parms, document)` and `encoder(bytes, parms,
  # document)` class methods, registered via `register_as`.
  module Filter
    autoload :Base, "pdfrb/filter/base"
    autoload :FlateDecode, "pdfrb/filter/flate_decode"
    autoload :ASCIIHexDecode, "pdfrb/filter/ascii_hex_decode"
    autoload :ASCII85Decode, "pdfrb/filter/ascii_85_decode"
    autoload :LZWDecode, "pdfrb/filter/lzw_decode"
    autoload :RunLengthDecode, "pdfrb/filter/run_length_decode"
    autoload :Crypt, "pdfrb/filter/crypt"
    autoload :DCTDecode, "pdfrb/filter/dct_decode"
    autoload :JPXDecode, "pdfrb/filter/jpx_decode"
    autoload :CCITTFaxDecode, "pdfrb/filter/ccitt_fax_decode"
    autoload :JBIG2Decode, "pdfrb/filter/jbig2_decode"
    autoload :BrotliDecode, "pdfrb/filter/brotli_decode"
    autoload :PNGPredictor, "pdfrb/filter/png_predictor"
    class << self
      def registry; @registry ||= {}; end

      def register(name, klass)
        registry[name.to_s] = klass
      end

      def [](name)
        registry[name.to_s]
      end

      # Force-load all filter implementations so register_as calls
      # fire and populate the registry. Idempotent.
      def eager_load!
        return if @eager_loaded

        constants.each do |c|
          const_get(c)
        rescue NameError
          # Skip autoload targets that don't define a class.
        end
        @eager_loaded = true
      end

      def apply(bytes, filters:, parms:, direction:, document: nil)
        eager_load!
        return bytes if filters.empty?

        case direction
        when :decode then decode_chain(bytes, filters, parms, document)
        when :encode then encode_chain(bytes, filters, parms, document)
        else raise ArgumentError, "unknown direction #{direction.inspect}"
        end
      end

      private

      def decode_chain(bytes, filters, parms, document)
        filters.each_with_index.reduce(bytes.dup) do |acc, (filter, i)|
          klass = self[filter] or raise Pdfrb::FilterError.new(
            "unknown filter #{filter.inspect}", filter_name: filter.to_s
          )
          klass.decoder(acc, parms[i], document)
        end
      end

      def encode_chain(bytes, filters, _parms, document)
        filters.reverse_each.reduce(bytes.dup) do |acc, filter|
          klass = self[filter] or raise Pdfrb::FilterError.new(
            "unknown filter #{filter.inspect}", filter_name: filter.to_s
          )
          klass.encoder(acc, nil, document)
        end
      end
    end
  end
end
