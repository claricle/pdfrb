# frozen_string_literal: true

require "stringio"

module Pdfrb
  module Content
    # Groups a token stream into (operator, operands) invocations.
    # Reuses +Source::Tokenizer+ for operand lexing (content streams
    # use the same PDF object syntax as COS values).
    #
    # Each invocation is yielded as `[operator_class, operands]`.
    class Parser
      attr_reader :tokenizer

      def initialize(tokenizer)
        @tokenizer = tokenizer
      end

      def self.parse(io_or_string)
        io = io_or_string.is_a?(::String) ? StringIO.new(io_or_string.b) : io_or_string
        new(Pdfrb::Source::Tokenizer.new(io))
      end

      # Yields (operator_class, operands) pairs. Returns an Enumerator
      # if no block.
      #
      # Special-cases the BI/ID/EI inline image sequence: when BI is
      # seen, the inline image dict + raw byte payload are read as a
      # single InlineImage invocation rather than as discrete tokens.
      def each_invocation
        return enum_for(:each_invocation) unless block_given?

        operands = []
        while (tok = tokenizer.next_token)
          if tok.type == :keyword && tok.value == "BI"
            yield Pdfrb::Content::Operator::BeginInlineImage, [parse_inline_image]
            operands = []
            next
          end

          case tok.type
          when :keyword
            op = Pdfrb::Content::Operator[tok.value]
            yield(op || Pdfrb::Content::Operator::Unknown, operands) if op
            operands = []
          when :name
            operands << Pdfrb::Model::Cos::NameEncoding.decode(tok.value)
          when :integer, :real, :true, :false, :null
            operands << tok.value
          when :string, :hex_string
            operands << tok.value
          when :array_open
            operands << consume_array
          when :dict_open
            operands << consume_dict
          end
        end
        self
      end

      # Parse a BI ... ID <bytes> EI inline image sequence. The BI
      # keyword has already been consumed; the next tokens form the
      # image header (key/value pairs), then ID introduces the raw
      # byte payload terminated by EI.
      #
      # Returns a Hash with :header (the key-value pairs) and
      # :data (the raw image bytes).
      def parse_inline_image
        header = {}
        # Read header pairs until we hit the ID keyword.
        while (tok = tokenizer.next_token)
          break if tok.type == :keyword && tok.value == "ID"

          if tok.type == :name
            key = abbrev_for(tok.value) || tok.value.to_sym
            val_tok = tokenizer.next_token
            header[key] = token_value(val_tok)
          end
        end

        # After ID, exactly one whitespace byte separates the
        # keyword from the data. Read raw bytes until "\nEI" or
        # " EI" terminator.
        data = read_inline_image_data
        Pdfrb::Content::InlineImage.new(header: header, data: data)
      end

      # Map inline-image abbreviation keys to full PDF names per
      # ISO 32000-2 §8.9.7 Table 89.
      def abbrev_for(name)
        ABBREV_TABLE[name.to_sym]
      end

      ABBREV_TABLE = {
        BPC: :BitsPerComponent,
        CS: :ColorSpace,
        D: :Decode,
        DP: :DecodeParms,
        F: :Filter,
        H: :Height,
        IM: :ImageMask,
        Intent: :Intent,
        I: :Interpolate,
        W: :Width,
      }.freeze

      def read_inline_image_data
        # Skip exactly one whitespace byte after ID.
        tokenizer.skip_whitespace
        bytes = +"".b
        # Read until we see the "EI" marker. The marker is usually
        # preceded by whitespace and followed by whitespace or EOF.
        until tokenizer.eof?
          b = tokenizer.read_byte
          break if b.nil?

          bytes << b
          if bytes.bytesize >= 3 &&
              whitespace_byte?(bytes.getbyte(-3)) &&
              bytes.byteslice(-2, 2) == "EI"
            return bytes.byteslice(0, bytes.bytesize - 3).b
          end
        end
        bytes.b
      end

      WHITESPACE_BYTE_VALUES = [0, 9, 10, 12, 13, 32].freeze

      def whitespace_byte?(byte)
        WHITESPACE_BYTE_VALUES.include?(byte)
      end

      private

      def consume_array
        arr = []
        loop do
          tok = tokenizer.next_token
          raise Pdfrb::SyntaxError, "unterminated array in content stream" if tok.nil?

          break if tok.type == :array_close

          arr << token_value(tok)
        end
        arr
      end

      def consume_dict
        hash = {}
        loop do
          tok = tokenizer.next_token
          raise Pdfrb::SyntaxError, "unterminated dict in content stream" if tok.nil?

          break if tok.type == :dict_close

          raise Pdfrb::SyntaxError, "dict key must be a name" unless tok.type == :name

          key = Pdfrb::Model::Cos::NameEncoding.decode(tok.value)
          val_tok = tokenizer.next_token
          hash[key] = token_value(val_tok)
        end
        hash
      end

      def token_value(tok)
        case tok.type
        when :name then Pdfrb::Model::Cos::NameEncoding.decode(tok.value)
        when :integer, :real, :true, :false, :null then tok.value
        when :string, :hex_string then tok.value
        when :array_open then consume_array
        when :dict_open then consume_dict
        else nil
        end
      end
    end

    module Operator
      # Placeholder for unknown operators (typically private
      # extensions). The Processor skips these.
      class Unknown < Base
        def self.name; "??"; end
      end
    end
  end
end
