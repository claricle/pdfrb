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
        # Decode +bytes+ (one byte per glyph) using +encoding_name+
        # (a Symbol like :WinAnsiEncoding) to Unicode.
        def decode(encoding_name, bytes)
          table = table_for(encoding_name)
          return bytes unless table

          bytes.each_byte.with_object(+"") do |b, buf|
            buf << (table[b] ? [table[b]].pack("U") : "?")
          end.encode("UTF-8")
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
      end
    end
  end
end
