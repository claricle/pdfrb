# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Post
        attr_reader :version, :italic_angle, :underline_position,
                    :underline_thickness, :is_fixed_pitch, :glyph_names

        def initialize(data)
          return unless data && data.bytesize >= 32

          @version = data.bytes[0, 4].pack("C*").unpack1("N")
          @italic_angle = s32(data, 4) / 65536.0
          @underline_position = s16(data, 8)
          @underline_thickness = s16(data, 10)
          @is_fixed_pitch = data.bytes[12, 4].pack("C*").unpack1("N")
          @glyph_names = parse_names(data) if @version == 0x00020000
        end

        def glyph_name(index)
          return nil unless @glyph_names
          return nil if index >= @glyph_names.length

          @glyph_names[index]
        end

        private

        def parse_names(data)
          count = u16(data, 32)
          indices = Array.new(count) { |i| u16(data, 34 + i * 2) }
          offset = 34 + count * 2
          custom_names = {}

          indices.each do |idx|
            next if idx < 258
            next if custom_names.key?(idx)

            len = data.getbyte(offset) || 0
            offset += 1
            custom_names[idx] = data.bytes[offset, len]&.pack("C*")&.force_encoding("UTF-8")
            offset += len
          end

          STANDARD_GLYPH_NAMES.map.with_index do |name, i|
            indices[i] && indices[i] < 258 ? STANDARD_GLYPH_NAMES[indices[i]] : custom_names[indices[i]]
          end
        rescue StandardError
          nil
        end

        def u16(data, off); (data.getbyte(off) << 8) | data.getbyte(off + 1); end
        def s16(data, off); v = u16(data, off); v >= 32768 ? v - 65536 : v; end
        def s32(data, off); (data.getbyte(off) << 24) | (data.getbyte(off + 1) << 16) | (data.getbyte(off + 2) << 8) | data.getbyte(off + 3); end

        STANDARD_GLYPH_NAMES = %w[
          .notdef .null nonmarkingreturn space exclam quotedbl numbersign
          dollar percent ampersand quotesingle parenleft parenright asterisk
          plus comma hyphen period slash zero one two three four five six
          seven eight nine colon semicolon less equal greater question at
          A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
          bracketleft backslash bracketright asciicircum underscore grave
          a b c d e f g h i j k l m n o p q r s t u v w x y z
          braceleft bar braceright asciitilde Adieresis Aring Ccedilla Eacute
          Ntilde Odieresis Udieresis aacute agrave acircumflex adieresis atilde
          aring ccedilla eacute egrave ecircumflex edieresis iacute igrave
          icircumflex idieresis ntilde oacute ograve ocircumflex odieresis
          otilde uacute ugrave ucircumflex udieresis dagger degree cent
          sterling section bullet paragraph germandbls registered copyright
          trademark acute dieresis notequal AE Oslash infinity plusminus
          lessequal greaterequal yen mu partialdiff summation product pi
          integral ordfeminine ordmasculine Omega ae oslash questiondown
          exclamdown logicalnot radical florin approxequal Delta guillemotleft
          guillemotright ellipsis nonbreakingspace Agrave Atilde Otilde OE oe
          endash emdash quotedblleft quotedblright quoteleft quoteright divide
          lozenge ydieresis Ydieresis fraction currency guilsinglleft
          guilsinglright fi fl daggerdbl periodcentered quotesinglbase
          quotedblbase perthousand Acircumflex Ecircumflex Aacute Edieresis
          Egrave Iacute Icircumflex Idieresis Eth eth Yacute yacute Thorne thorn
          multiply minus onesuperior twosuperior threesuperior onehalf
          onequarter threequarters franc Gbreve gbreve Idotaccent Scedilla
          scedilla Cacute cacute Ccaron ccaron dcroat
        ].freeze
      end
    end
  end
end
