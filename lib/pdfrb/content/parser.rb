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
      def each_invocation
        return enum_for(:each_invocation) unless block_given?

        operands = []
        while (tok = tokenizer.next_token)
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
