# frozen_string_literal: true

module Pdfrb
  module Arlington
    # Predicate grammar (one component of the TSV model). Each
    # predicate is `fn:Name(args, ...)`. Predicates compose via
    # `&&`, `||`, `!`. The grammar does NOT support operator
    # precedence — every `&&`/`||` must be fully parenthesised.
    module Predicate
      autoload :Lexer, "pdfrb/arlington/predicate/lexer"
      autoload :Parser, "pdfrb/arlington/predicate/parser"
      autoload :AST, "pdfrb/arlington/predicate/ast"
      autoload :Evaluator, "pdfrb/arlington/predicate/evaluator"
      autoload :Context, "pdfrb/arlington/predicate/context"
      autoload :Functions, "pdfrb/arlington/predicate/functions"
    end
  end
end
