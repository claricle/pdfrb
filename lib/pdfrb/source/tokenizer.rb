# frozen_string_literal: true

module Pdfrb
  module Source
    # Byte-level PDF lexer (s7.2). State machine that emits Token
    # values via +next_token+ / +peek+. Pull-based so the Parser can
    # stream through arbitrarily large PDFs without materialising the
    # whole token stream.
    #
    # States:
    #   :top       — between tokens; dispatch by first byte.
    #   :string    — inside (...) with depth tracking and \ escapes.
    #   :hexstring — inside <...> (after distinguishing << as dict open).
    #   :comment   — inside %... until EOL.
    #
    # The keyword set per s7.2: obj/endobj/stream/endstream/xref/
    # startxref/trailer/true/false/null. The Tokenizer emits them with
    # type :keyword and value equal to the keyword string; the Parser
    # dispatches on the value.
    class Tokenizer
      WHITESPACE_BYTES = PdfConstants::WHITESPACE.bytes.to_set.freeze
      DELIMITER_BYTES  = PdfConstants::DELIMITERS.bytes.to_set.freeze

      # Public so the Parser can recognise the same set when scanning
      # post-stream whitespace.
      public_constant :WHITESPACE_BYTES
      public_constant :DELIMITER_BYTES

      attr_reader :pos, :io

      def initialize(io)
        @io = io
        @pos = 0
        @pushback = []
        @lookahead = []
      end

      def next_token
        return @pushback.pop unless @pushback.empty?

        fill_lookahead(1) if @lookahead.empty?
        @lookahead.shift
      end

      def peek(offset = 0)
        fill_lookahead(offset + 1)
        @lookahead[offset]
      end

      def pushback(token)
        @pushback << token
        self
      end

      # Whether the underlying IO is at end of stream.
      def eof?
        @io.eof?
      end

      # Read one byte from the underlying IO. Returns nil at EOF.
      def read_byte
        b = @io.getbyte
        @pos += 1 if b
        b
      end

      # Skip whitespace bytes (NUL, HT, LF, FF, CR, SP).
      def skip_whitespace
        while (b = peek_byte)
          break unless WHITESPACE_BYTES.include?(b)

          advance_byte
        end
      end

      private

      def fill_lookahead(n)
        while @lookahead.length < n
          tok = lex_one
          break if tok.nil?

          @lookahead << tok
        end
      end

      def lex_one
        skip_whitespace_and_comments
        return nil if eos?

        start_pos = @pos
        b = peek_byte
        case b
        when 40  then read_string(start_pos)
        when 60
          peek_byte(1) == 60 ? read_two_byte_token(:dict_open, "<<", start_pos) : read_hex_string(start_pos)
        when 62
          peek_byte(1) == 62 ? read_two_byte_token(:dict_close, ">>", start_pos) : raise(lex_error("lone '>' at #{start_pos}"))
        when 91  then advance_byte && emit(:array_open, "[", start_pos)
        when 93  then advance_byte && emit(:array_close, "]", start_pos)
        when 47  then read_name(start_pos)
        when 43, 45, 46, *digit_bytes then read_number_or_keyword(start_pos)
        else read_keyword(start_pos)
        end
      end

      def digit_bytes
        (48..57).to_a
      end
      private :digit_bytes

      def eos?
        @io.eof?
      end

      def peek_byte(offset = 0)
        cur = @io.pos
        if offset.zero?
          b = @io.getbyte
          @io.seek(cur, IO::SEEK_SET) if b
          return b
        end

        @io.seek(cur + offset, IO::SEEK_SET)
        b = @io.getbyte
        @io.seek(cur, IO::SEEK_SET)
        b
      end

      def advance_byte
        @pos += 1
        @io.getbyte
      end

      # Append an Integer byte to +buf+ without re-encoding through
      # UTF-8 (which is the default for `+""` in a UTF-8 source file).
      def append_byte(buf, b)
        buf << b.chr(Encoding::BINARY)
      end

      def skip_whitespace_and_comments
        loop do
          break if eos?

          b = peek_byte
          if WHITESPACE_BYTES.include?(b)
            advance_byte
          elsif b == 37 # %
            skip_comment
          else
            break
          end
        end
      end

      def skip_comment
        until eos? || peek_byte == 10 # \n
          advance_byte
        end
        advance_byte if !eos? && peek_byte == 10
        nil
      end

      def read_two_byte_token(type, literal, start_pos)
        advance_byte
        advance_byte
        emit(type, literal, start_pos)
      end

      def read_string(start_pos)
        advance_byte # consume (
        depth = 1
        bytes = +""
        until eos?
          b = advance_byte
          case b
          when 92 # backslash
            esc = read_string_escape
            append_byte(bytes, esc) if esc >= 0
          when 40 # (
            depth += 1
            append_byte(bytes, 40)
          when 41 # )
            depth -= 1
            break if depth.zero?

            append_byte(bytes, 41)
          else
            append_byte(bytes, b)
          end
        end
        raise lex_error("unterminated string at #{start_pos}") if depth.positive?

        emit(:string, bytes.force_encoding(Encoding::BINARY), start_pos)
      end

      def read_string_escape
        b = advance_byte
        case b
        when 110 then 10    # \n
        when 114 then 13    # \r
        when 116 then 9     # \t
        when 98  then 8     # \b
        when 102 then 12    # \f
        when 40  then 40    # \(
        when 41  then 41    # \)
        when 92  then 92    # \\
        when 48..55 then read_octal_escape(b)
        when 10, 13
          # Line continuation — eat CRLF/LF/CR; emit no byte.
          advance_byte if b == 13 && peek_byte == 10
          -1
        else b
        end
      end

      def read_octal_escape(first)
        digits = [first]
        2.times do
          break if eos?

          b = peek_byte
          break unless (48..55).cover?(b)

          digits << advance_byte
        end
        digits.map(&:chr).join.to_i(8) & 0xFF
      end

      def read_hex_string(start_pos)
        advance_byte # consume <
        bytes = +""
        hi = nil
        until eos?
          b = advance_byte
          break if b == 62 # >

          next if WHITESPACE_BYTES.include?(b)

          nibble = hex_value(b)
          raise lex_error("bad hex digit #{b.chr.inspect} at #{@pos}") unless nibble

          if hi.nil?
            hi = nibble
          else
            append_byte(bytes, hi * 16 + nibble)
            hi = nil
          end
        end
        append_byte(bytes, hi * 16 + 0) if hi # odd nibble padded with 0
        emit(:hex_string, bytes.force_encoding(Encoding::BINARY), start_pos)
      end

      def hex_value(b)
        return (b - 48) if (48..57).cover?(b)
        return (b - 55) if (65..70).cover?(b)
        return (b - 87) if (97..102).cover?(b)

        nil
      end

      def read_name(start_pos)
        advance_byte # consume /
        bytes = +""
        until eos?
          b = peek_byte
          break if WHITESPACE_BYTES.include?(b) || DELIMITER_BYTES.include?(b)

          advance_byte
          if b == 35 # # — expect two hex digits
            hi = peek_byte
            lo = peek_byte(1)
            if hi && lo && (n1 = hex_value(hi)) && (n2 = hex_value(lo))
              advance_byte; advance_byte
              append_byte(bytes, n1 * 16 + n2)
            else
              append_byte(bytes, 35)
            end
          else
            append_byte(bytes, b)
          end
        end
        emit(:name, bytes.force_encoding(Encoding::BINARY), start_pos)
      end

      def read_number_or_keyword(start_pos)
        bytes = +""
        append_byte(bytes, advance_byte) # first char
        until eos?
          b = peek_byte
          break if WHITESPACE_BYTES.include?(b) || DELIMITER_BYTES.include?(b)

          advance_byte
          append_byte(bytes, b)
        end
        emit_number_or_keyword(bytes, start_pos)
      end

      def read_keyword(start_pos)
        bytes = +""
        until eos?
          b = peek_byte
          break if WHITESPACE_BYTES.include?(b) || DELIMITER_BYTES.include?(b)

          advance_byte
          append_byte(bytes, b)
        end
        emit_keyword(bytes, start_pos)
      end

      def emit_number_or_keyword(bytes, start_pos)
        if bytes.match?(/\A[-+]?\d+\z/)
          emit(:integer, bytes.to_i, start_pos)
        elsif bytes.match?(/\A[-+]?(\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?\z/) && (bytes.include?(".") || bytes =~ /[eE]/)
          emit(:real, bytes.to_f, start_pos)
        else
          emit_keyword(bytes, start_pos)
        end
      end

      def emit_keyword(bytes, start_pos)
        case bytes
        when "true"  then emit(:true, true, start_pos)
        when "false" then emit(:false, false, start_pos)
        when "null"  then emit(:null, nil, start_pos)
        else emit(:keyword, bytes, start_pos)
        end
      end

      def emit(type, value, position)
        Token.new(type: type, value: value, position: position)
      end

      def lex_error(message)
        Pdfrb::LexError.new(message, source_position: @pos)
      end
    end
  end
end
