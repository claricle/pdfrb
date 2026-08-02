# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Recursive-descent parser. Builds AST from tokens. Per the
      # Arlington grammar: `&&` and `||` must be fully parenthesised
      # (no precedence); we enforce that by only accepting them inside
      # `(...)` groups.
      class Parser
        attr_reader :tokens, :ast

        def initialize(tokens)
          @tokens = tokens
          @pos = 0
        end

        def self.parse(tokens_or_source)
          toks = tokens_or_source.is_a?(::String) ? Lexer.tokenize(tokens_or_source) : tokens_or_source
          new(toks).parse
        end

        def parse
          return nil if tokens.empty?

          node = parse_expr
          raise Pdfrb::SyntaxError, "trailing tokens at pos #{@pos}" unless eof?

          node
        end

        private

        def peek(offset = 0)
          tokens[@pos + offset]
        end

        def advance
          tok = tokens[@pos]
          @pos += 1
          tok
        end

        def eof?
          @pos >= tokens.length
        end

        def expect(type)
          tok = advance
          unless tok&.first == type
            raise Pdfrb::SyntaxError,
                  "expected #{type}, got #{tok.inspect} at pos #{@pos}"
          end

          tok
        end

        def parse_expr
          tok = peek
          return nil unless tok

          case tok.first
          when :lparen then parse_group
          when :fn_call then parse_logical_continuation(parse_fn_call)
          when :logic_and, :logic_or then parse_logical_continuation(parse_primary)
          else
            parse_logical_continuation(parse_comparison)
          end
        end

        def parse_group
          expect(:lparen)
          node = parse_expr
          expect(:rparen)
          node
        end

        def parse_fn_call
          name = advance.last
          expect(:lparen)
          args = parse_arg_list
          expect(:rparen)
          AST::FunctionCall.new(name: name, args: args)
        end

        def parse_arg_list
          args = []
          return args if peek&.first == :rparen

          loop do
            args << parse_expr
            break unless peek&.first == :comma

            advance
          end
          args
        end

        def parse_comparison
          left = parse_primary
          while peek&.first == :op && %i[== :!= :< :> :<= :>=].include?(peek.last)
            op = advance.last
            right = parse_primary
            left = AST::BinOp.new(op: op, left: left, right: right)
          end
          left
        end

        def parse_logical_continuation(left)
          # Only used inside a parenthesised group; the top level
          # rejects stray && / ||.
          while %i[logic_and logic_or].include?(peek&.first)
            op_tok = advance
            op = op_tok.first == :logic_and ? :"&&" : :"||"
            right = parse_comparison
            left = AST::LogicalOp.new(op: op, left: left, right: right)
          end
          left
        end

        def parse_primary
          tok = peek
          return nil unless tok

          case tok.first
          when :at_key then AST::AtKey.new(name: advance.last)
          when :path then AST::PathExpr.new(segments: advance.last.split("::"))
          when :number then AST::Literal.new(value: coerce_number(advance.last))
          when :string then AST::Literal.new(value: advance.last)
          when :name
            n = advance.last
            AST::Literal.new(value: n.to_sym)
          when :array then parse_array_literal(advance.last)
          when :unary_not
            advance
            AST::UnaryOp.new(op: :!, operand: parse_primary)
          when :lparen then parse_group
          when :fn_call then parse_fn_call
          when :logic_and, :logic_or then parse_logical_continuation(parse_primary)
          else
            raise Pdfrb::SyntaxError, "unexpected token #{tok.inspect} at pos #{@pos}"
          end
        end

        def parse_array_literal(body)
          # The lexer stripped outer [ ]; split on whitespace and
          # parse each as a primary. For nested arrays (complex types),
          # re-add brackets and re-tokenise.
          inner = body.strip
          return AST::ArrayLit.new(values: []) if inner.empty?

          if inner.start_with?("[")
            # Re-parse nested arrays by feeding back through the lexer.
            values = inner.scan(/\[[^\]]+\]/).map do |sub|
              sub_body = sub[1..-2]
              AST::ArrayLit.new(values: sub_body.split(/\s+/).filter_map do |v|
                v.match?(/\A-?\d/) ? coerce_number(v) : v.to_sym
              end)
            end
            return AST::ArrayLit.new(values: values)
          end

          AST::ArrayLit.new(values: inner.split(/\s+/).filter_map do |v|
            v.match?(/\A-?\d/) ? coerce_number(v) : v.to_sym
          end)
        end

        def coerce_number(str)
          return str.to_i if str.match?(/\A-?\d+\z/)

          if (m = str.match(/\A(\d+)\.(\d+)\z/))
            major = m[1].to_i
            minor = m[2].to_i
            return PdfVersion.new(str) if (major == 1 && (0..7).cover?(minor)) || (major == 2 && minor.zero?)

            return str.to_f
          end
          return str.to_f if str.match?(/\A-?\d*\.\d+\z/) || str.match?(/\A-?\d+\.\d*\z/)

          str
        end
      end
    end
  end
end
