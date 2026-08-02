# frozen_string_literal: true

require "stringio"

module Pdfrb
  module Source
    # Recursive-descent parser. Consumes tokens from a +Tokenizer+
    # and produces Pdfrb::Model values.
    #
    # Recognised productions:
    #   value      := scalar | array | dict | stream_indirect
    #   scalar     := number | name | string | hex_string | boolean | null | ref
    #   ref        := integer integer 'R'
    #   array      := '[' value* ']'
    #   dict       := '<<' (name value)* '>>'
    #   obj_decl   := integer integer 'obj'
    #   stream_obj := obj_decl dict 'stream' <bytes> 'endstream' 'endobj'
    #
    # References are emitted as +Model::Reference+ values (deferred
    # resolution). The caller resolves them via the owning Document.
    class Parser
      attr_reader :tokenizer, :document

      def initialize(tokenizer, document: nil)
        @tokenizer = tokenizer
        @document = document
      end

      def parse_value
        tok = tokenizer.next_token
        return nil if tok.nil?

        case tok.type
        when :integer, :real then maybe_reference(tok) || tok.value
        when :name then Pdfrb::Model::Cos::NameEncoding.decode(tok.value)
        when :string, :hex_string then tok.value
        when :true then true
        when :false then false
        when :null then nil
        when :array_open then parse_array_body
        when :dict_open then parse_dict_body
        else
          raise syntax_error("unexpected token #{tok.inspect}")
        end
      end

      # Parse `<N> <G> obj <body> endobj` (with optional stream).
      # Returns a Model::Object subclass (Dictionary / Stream / etc.).
      def parse_indirect_object
        oid = expect_type(:integer).value
        gen = expect_type(:integer).value
        expect_keyword("obj")
        value = parse_value
        tok = tokenizer.peek
        if tok&.type == :keyword && tok.value == "stream"
          tokenizer.next_token
          stream = read_stream_payload(value)
          expect_keyword("endstream")
          expect_keyword("endobj")
          wrap_stream(value, stream, oid: oid, gen: gen)
        else
          expect_keyword("endobj")
          wrap_object(value, oid: oid, gen: gen)
        end
      end

      def parse_dict
        tok = tokenizer.peek
        return nil if tok.nil?
        raise syntax_error("expected <<, got #{tok.inspect}") unless tok.type == :dict_open

        tokenizer.next_token
        parse_dict_body
      end

      private

      def parse_array_body
        arr = []
        loop do
          tok = tokenizer.peek
          raise syntax_error("unterminated array") if tok.nil?

          break if tok.type == :array_close

          arr << parse_value
        end
        tokenizer.next_token # consume ]
        arr
      end

      def parse_dict_body
        hash = {}
        loop do
          tok = tokenizer.peek
          raise syntax_error("unterminated dict") if tok.nil?

          break if tok.type == :dict_close

          key_tok = tokenizer.next_token
          unless key_tok.type == :name
            raise syntax_error("dict key must be a name, got #{key_tok.inspect}")
          end

          key = Pdfrb::Model::Cos::NameEncoding.decode(key_tok.value)
          hash[key] = parse_value
        end
        tokenizer.next_token # consume >>
        hash
      end

      # Lookahead: if next two tokens are <int> <'R'>, this is a Reference.
      def maybe_reference(first_tok)
        n1 = tokenizer.peek(0)
        n2 = tokenizer.peek(1)
        return nil unless n1&.type == :integer
        return nil unless n2&.type == :keyword && n2.value == "R"

        tokenizer.next_token # consume n1
        tokenizer.next_token # consume R
        Pdfrb::Model::Reference.new(first_tok.value.to_i, n1.value.to_i)
      end

      def read_stream_payload(dict_value)
        skip_single_eol
        # Always scan for "endstream" from the current position.
        # /Length is unreliable in real-world PDFs (generator bugs,
        # CRLF→LF conversion). Scanning is correct in all cases.
        scan_to_endstream
      end

      def endstream_next?
        cur = io.pos
        b = io.getbyte
        return false unless b

        io.ungetbyte(b)
        # Skip whitespace (max 2 bytes) then check for "endstream".
        skipped = 0
        while skipped < 2
          b = io.getbyte
          break unless b && Pdfrb::Source::Tokenizer::WHITESPACE_BYTES.include?(b)

          skipped += 1
        end
        io.ungetbyte(b) if b && !Pdfrb::Source::Tokenizer::WHITESPACE_BYTES.include?(b)
        peek_str = io.read(9)
        io.seek(cur, IO::SEEK_SET)
        peek_str == "endstream"
      end

      def scan_to_endstream
        start = io.pos
        chunk = io.read
        idx = chunk.index("endstream")
        if idx
          # Position IO at the start of "endstream" so the caller's
          # expect_keyword("endstream") can consume it normally.
          io.seek(start + idx, IO::SEEK_SET)
          content = chunk.byteslice(0, idx)
          # Strip one trailing EOL before "endstream" (spec: it's
          # not part of the stream data).
          content = content.sub(/\r?\n\z/, "".b) if content.end_with?("\n")
          content
        else
          io.seek(start, IO::SEEK_SET)
          +""
        end
      end

      def length_of(dict_value)
        return nil unless dict_value.is_a?(::Hash)

        case dict_value[:Length]
        when Integer then dict_value[:Length]
        when Pdfrb::Model::Reference
          @document ? (@document.object(dict_value[:Length])&.value rescue nil) : nil
        end
      end

      def read_bytes(n)
        return +"".b if n.nil? || n.negative?

        bytes = io.read(n) || +"".b
        bytes.force_encoding(Encoding::BINARY)
      end

      def scan_to_endstream_length
        # No /Length — scan from current pos to next "endstream".
        # Returns the byte count up to (but not including) "endstream".
        start = io.pos
        chunk_size = 4096
        window = +""
        offset = 0
        loop do
          io.seek(start + offset, IO::SEEK_SET)
          piece = io.read(chunk_size)
          break unless piece

          window << piece
          idx = window.index("endstream")
          if idx
            io.seek(start + idx + "endstream".length, IO::SEEK_SET)
            return idx
          end
          offset += [piece.length - "endstream".length + 1, 1].max
        end
        io.seek(start, IO::SEEK_SET)
        0
      end

      def skip_single_eol
        b = io.getbyte
        return unless b

        if b == 13 # \r
          b2 = io.getbyte
          io.ungetbyte(b2) unless b2.nil? || b2 == 10
        elsif b != 10
          io.ungetbyte(b)
        end
      end

      def skip_whitespace
        loop do
          b = io.getbyte
          break if b.nil?

          if Pdfrb::Source::Tokenizer::WHITESPACE_BYTES.include?(b)
            next
          else
            io.ungetbyte(b)
            break
          end
        end
      rescue EOFError
        nil
      end

      def io
        tokenizer.io
      end

      def wrap_object(value, oid:, gen:)
        case value
        when ::Hash
          Pdfrb::Model::Cos::Dictionary.new(value, oid: oid, gen: gen, document: @document)
        when ::Array
          Pdfrb::Model::PdfArray.new(value, oid: oid, gen: gen, document: @document)
        else
          Pdfrb::Model::Object.new(value, oid: oid, gen: gen, document: @document)
        end
      end

      def wrap_stream(dict_value, bytes, oid:, gen:)
        dict = dict_value.is_a?(::Hash) ? dict_value : {}
        Pdfrb::Model::Cos::Stream.new(dict, stream: bytes, oid: oid, gen: gen, document: @document)
      end

      def expect_type(type)
        tok = tokenizer.next_token
        raise syntax_error("expected #{type}, got #{tok.inspect}") unless tok&.type == type

        tok
      end

      def expect_keyword(name)
        tok = tokenizer.next_token
        unless tok&.type == :keyword && tok.value == name
          raise syntax_error("expected keyword #{name.inspect}, got #{tok.inspect}")
        end

        tok
      end

      def syntax_error(message)
        Pdfrb::SyntaxError.new(message, source_position: tokenizer.pos)
      end
    end
  end
end
