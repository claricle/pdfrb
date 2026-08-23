# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # EmbeddedFileParameterDictionary (s7.11.3.1). Per /EF entry
      # /Params dict — checksum, size, dates, mac creator.
      class EmbeddedFileParameter < Pdfrb::Model::Cos::Dictionary
        arlington_object "EmbeddedFileParameter"
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
    end
  end
end
