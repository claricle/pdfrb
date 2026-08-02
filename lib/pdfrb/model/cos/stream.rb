# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # A Dictionary with an associated raw byte payload (s7.3.8.1).
      # Filters (s7.4) are applied on read via `decoded_stream` and on
      # write via `encoded_stream=`.
      class Stream < Dictionary
        def initialize(value = {}, stream: "".b, oid: 0, gen: 0, document: nil)
          super(value, oid: oid, gen: gen, document: document)
          @stream = stream.to_s.dup.force_encoding(Encoding::BINARY)
        end

        attr_reader :stream

        def stream=(bytes)
          @stream = bytes.to_s.dup.force_encoding(Encoding::BINARY)
          @value[:Length] = @stream.bytesize
        end

        # Apply /Filter pipeline (if any) to decode the raw stream.
        # Returns raw bytes when no filter or /Filter /Identity.
        def decoded_stream
          filter = raw_filter
          return @stream if filter.nil? || filter == :Identity

          unless Pdfrb.const_defined?(:Filter)
            raise Pdfrb::FilterError, "Filter layer not loaded"
          end

          Pdfrb::Filter.apply(
            @stream,
            filters: as_filter_list(filter),
            parms: as_parms_list(raw_decode_parms),
            direction: :decode,
            document: document
          )
        end

        # Apply /Filter pipeline in reverse to encode +bytes+. Sets
        # /Length to the encoded byte count.
        def encoded_stream=(bytes)
          filter = raw_filter
          if filter.nil?
            @stream = bytes.to_s.dup.force_encoding(Encoding::BINARY)
          else
            @stream = Pdfrb::Filter.apply(
              bytes,
              filters: as_filter_list(filter),
              parms: as_parms_list(raw_decode_parms),
              direction: :encode,
              document: document
            )
          end
          @value[:Length] = @stream.bytesize
        end

        private

        def raw_filter
          @value[:Filter]
        end

        def raw_decode_parms
          @value[:DecodeParms] || @value[:DP]
        end

        # Normalise /Filter to an Array of filter names. /Filter may
        # be a single Name or an Array of Names.
        def as_filter_list(filter)
          case filter
          when ::Array then filter
          when Pdfrb::Model::PdfArray then filter.value
          else [filter]
          end
        end

        # Normalise /DecodeParms to an Array of Hashes (one per
        # filter). /DecodeParms may be a single Hash (applies to all
        # filters) or an Array of Hashes.
        # NOTE: Array(Hash) returns [[:k, :v], ...], NOT [hash]. We
        # must check the type explicitly.
        def as_parms_list(parms)
          case parms
          when nil then []
          when ::Array then parms
          when Pdfrb::Model::PdfArray then parms.value
          when ::Hash then [parms]
          else [parms]
          end
        end
      end
    end
  end
end
