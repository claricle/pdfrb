# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Tokenises the predicate mini-DSL.
      #
      #   fn:IsRequired(@Foo==Bar && fn:SinceVersion(2.0))
      #
      # Produces a stream of Token values: `[:fn_call, "fn:IsRequired"]`,
      # `[:lparen]`, `[:at_key, "Foo"]`, `[:op, "=="]`, `[:name, "Bar"]`,
      # `[:logic_and]`, `[:fn_call, "fn:SinceVersion"]`, `[:lparen]`,
      # `[:version, "2.0"]`, `[:rparen]`, `[:rparen]`.
      class Lexer
        attr_reader :source, :tokens

        def initialize(source)
          @source = source.to_s
          @tokens = []
          @pos = 0
        end

        def self.tokenize(source)
          new(source).tokenize
        end

        def tokenize
          while @pos < @source.length
            ch = peek
            if ch =~ /\s/
              advance
            elsif start_fn_call?
              scan_fn_call
            elsif ch == "@"
              scan_at_key
            elsif ch =~ /[0-9]/
              scan_number
            elsif ch == "'"
              scan_quoted_string
            elsif ch == "["
              scan_array
            elsif ch =~ /[A-Za-z_]/
              scan_name_or_path
            elsif start_two_char_op?
              scan_two_char_op
            elsif ch =~ /[!()<>,&|*+\-\/%=]/
              scan_single_char
            else
              raise Pdfrb::LexError,
                    "predicate lexer: unexpected char #{ch.inspect} at pos #{@pos}"
            end
          end
          @tokens.freeze
        end

        private

        def peek(offset = 0)
          @source[@pos + offset]
        end

        def advance(n = 1)
          tok = @source[@pos, n]
          @pos += n
          tok
        end

        def start_fn_call?
          @source[@pos, 3] == "fn:" &&
            @source[@pos + 3, 1] =~ /[A-Z]/
        end

        def scan_fn_call
          advance(3) # consume fn:
          name = +""
          while @pos < @source.length && peek =~ /[A-Za-z0-9_]/
            name << advance
          end
          @tokens << [:fn_call, "fn:#{name}"]
        end

        def scan_at_key
          advance # consume @
          name = +""
          while @pos < @source.length && peek =~ /[A-Za-z0-9_]/
            name << advance
          end
          @tokens << [:at_key, name.to_s]
        end

        def scan_number
          num = +""
          while @pos < @source.length && peek =~ /[0-9eE.+\-]/
            num << advance
          end
          @tokens << [:number, num.to_s]
        end

        def scan_quoted_string
          advance # consume '
          body = +""
          while @pos < @source.length && peek != "'"
            body << advance
          end
          advance # consume closing '
          @tokens << [:string, body.to_s]
        end

        def scan_array
          advance # consume [
          body = +""
          depth = 1
          while @pos < @source.length && depth.positive?
            ch = advance
            if ch == "["
              depth += 1
              body << ch
            elsif ch == "]"
              depth -= 1
              body << ch if depth.positive?
            else
              body << ch
            end
          end
          @tokens << [:array, body.to_s.strip]
        end

        def scan_name_or_path
          name = +""
          while @pos < @source.length && peek =~ /[A-Za-z0-9_:]/
            name << advance
          end
          if name.include?("::")
            @tokens << [:path, name.to_s]
          else
            @tokens << [:name, name.to_s]
          end
        end

        def start_two_char_op?
          two = @source[@pos, 2]
          %w[== != <= >= && ||].include?(two)
        end

        def scan_two_char_op
          tok = advance(2)
          case tok
          when "==" then @tokens << [:op, :==]
          when "!=" then @tokens << [:op, :"!="]
          when "<=" then @tokens << [:op, :<=]
          when ">=" then @tokens << [:op, :>=]
          when "&&" then @tokens << [:logic_and]
          when "||" then @tokens << [:logic_or]
          end
        end

        def scan_single_char
          ch = advance
          case ch
          when "(" then @tokens << [:lparen]
          when ")" then @tokens << [:rparen]
          when "," then @tokens << [:comma]
          when "<" then @tokens << [:op, :<]
          when ">" then @tokens << [:op, :>]
          when "!" then @tokens << [:unary_not]
          when "+" then @tokens << [:op, :+]
          when "-" then @tokens << [:op, :-]
          when "*" then @tokens << [:op, :*]
          when "/" then @tokens << [:op, :/]
          when "%" then @tokens << [:op, :%]
          when "=" then @tokens << [:op, :==]
          end
        end
      end
    end
  end
end
