# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # EmbeddedFileParameterDictionary (s7.11.3.1). Per /EF entry
      # /Params dict — checksum, size, dates, mac creator.
      class EmbeddedFileParameter < Pdfrb::Model::Cos::Dictionary
        def size; self[:Size]; end
        def creation_date; self[:CreationDate]; end
        def modification_date; self[:ModDate]; end
        def mac; self[:Mac]; end
        def checksum; self[:CheckSum]; end

        def has_checksum?
          !!checksum
        end

        def creation_time
          time = creation_date
          return nil unless time

          time.is_a?(Time) ? time : parse_pdf_date(time.to_s)
        end

        def modification_time
          time = modification_date
          return nil unless time

          time.is_a?(Time) ? time : parse_pdf_date(time.to_s)
        end

        private

        def parse_pdf_date(str)
          match = str.to_s.match(/^D:(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?/)
          return nil unless match

          Time.new(match[1].to_i, match[2].to_i, match[3].to_i,
                   (match[4] || 0).to_i, (match[5] || 0).to_i, (match[6] || 0).to_i,
                   "+00:00")
        rescue StandardError
          nil
        end
      end

      # JBIG2 Globals stream (s7.4.7). Holds shared JBIG2 segment
      # data referenced by /DecodeParms /JBIG2Globals.
      class JBIG2Globals < Pdfrb::Model::Cos::Stream
        def globals_data
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end

      # URL Alias (s7.9.6). Names dictionary entry mapping friendly
      # URLs to actual URLs for collection sub-items.
      class URLAlias < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def alias_value; self[:U]; end
        def url; self[:URL]; end

        def has_alias?
          !!alias_value
        end
      end

      # URI dict (s12.5.6.5). Catalog /URI dict for base URI and
      # retriever map.
      class URIDict < Pdfrb::Model::Cos::Dictionary
        def base; self[:Base]; end
        def retriever_map; self[:Map]; end

        def has_base?
          !!base
        end
      end
    end
  end
end
