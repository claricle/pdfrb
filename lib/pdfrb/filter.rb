# frozen_string_literal: true

module Pdfrb
  # Stream filter pipeline (s7.4). Each filter is a stateless class
  # with `decoder(bytes, parms, document)` and `encoder(bytes, parms,
  # document)` class methods, registered via `register_as`.
  module Filter
    autoload :Base, "pdfrb/filter/base"

    class << self
      def registry; @registry ||= {}; end

      def register(name, klass)
        registry[name.to_s] = klass
      end

      def [](name)
        registry[name.to_s]
      end

      def apply(bytes, filters:, parms:, direction:, document: nil)
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

# Eager-load filters so register_as calls populate the registry
# before any stream decode happens. Must be after the Filter module
# and its singleton methods are fully defined.
require "pdfrb/filter/base"
require "pdfrb/filter/flate_decode"
require "pdfrb/filter/ascii_hex_decode"
require "pdfrb/filter/ascii_85_decode"
require "pdfrb/filter/lzw_decode"
require "pdfrb/filter/run_length_decode"
require "pdfrb/filter/crypt"
require "pdfrb/filter/passthrough_filters"
