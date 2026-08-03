# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      autoload :PDFDocEncoding, "pdfrb/font/encoding/pdf_doc_encoding"
      autoload :StandardEncoding, "pdfrb/font/encoding/standard_encoding"
      autoload :WinAnsiEncoding, "pdfrb/font/encoding/win_ansi_encoding"
      autoload :MacRomanEncoding, "pdfrb/font/encoding/mac_roman_encoding"
      autoload :ZapfDingbatsEncoding, "pdfrb/font/encoding/zapf_dingbats_encoding"

      class << self
        def decode(encoding_name, bytes)
          table = table_for(encoding_name)
          return bytes unless table

          bytes.each_byte.with_object(+"") do |b, buf|
            cp = table.is_a?(::Array) ? table[b] : table[b.to_s.to_sym]
            buf << (cp ? [cp].pack("U") : "?")
          end.encode("UTF-8")
        end

        def encode(encoding_name, text)
          table = table_for(encoding_name)
          return text.to_s.b unless table

          reverse = reverse_table_for(encoding_name)
          text.to_s.each_char.with_object(+"") do |ch, buf|
            cp = ch.ord
            byte = reverse[cp] || (cp < 0x80 ? cp : nil)
            buf << [byte || 0x3F].pack("C")
          end.b
        end

        def table_for(name)
          case name.to_sym
          when :WinAnsiEncoding then WinAnsiEncoding::TABLE
          when :MacRomanEncoding then MacRomanEncoding::TABLE
          when :StandardEncoding then StandardEncoding::TABLE
          when :PDFDocEncoding then PDFDocEncoding::TABLE
          when :ZapfDingbatsEncoding then ZapfDingbatsEncoding::TABLE
          end
        end

        def reverse_table_for(name)
          @reverse_tables ||= {}
          @reverse_tables[name] ||= build_reverse_table(name)
        end

        def build_reverse_table(name)
          table = table_for(name)
          return {} unless table

          if table.is_a?(::Array)
            table.each_with_index.with_object({}) do |(cp, byte), h|
              h[cp] = byte if cp
            end
          else
            table.each_with_object({}) { |(byte, cp), h| h[cp] = byte }
          end
        end
      end
    end
  end
end
