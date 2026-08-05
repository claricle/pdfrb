# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Document info dict (s7.9.3). Title/Author/Subject/Keywords/
      # Creator/Producer/CreationDate/ModDate/Trapped.
      # Pre-PDF-2.0; superseded by /Metadata XMP in modern docs but
      # still widely used.
      class Info < Pdfrb::Model::Cos::Dictionary
        arlington_object "DocInfo"

        def title; self[:Title]; end
        def author; self[:Author]; end
        def subject; self[:Subject]; end
        def keywords; self[:Keywords]; end
        def creator; self[:Creator]; end
        def producer; self[:Producer]; end
        def creation_date; self[:CreationDate]; end
        def modification_date; self[:ModDate]; end
        def trapped; self[:Trapped]; end

        def trapped?
          trapped&.to_sym == :True
        end

        def creation_time
          parse_pdf_date(creation_date)
        end

        def modification_time
          parse_pdf_date(modification_date)
        end

        private

        def parse_pdf_date(str)
          return nil unless str
          match = str.match(/^D:(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?/)
          return nil unless match

          year = match[1].to_i
          month = match[2].to_i
          day = match[3].to_i
          hour = (match[4] || 0).to_i
          min = (match[5] || 0).to_i
          sec = (match[6] || 0).to_i

          Time.new(year, month, day, hour, min, sec, "+00:00")
        rescue StandardError
          nil
        end
      end
    end
  end
end
