# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # AST node types for the predicate grammar. Each is a small
      # immutable Struct-like class with the operands it carries.
      module AST
        FunctionCall = Struct.new(:name, :args, keyword_init: true)
        AtKey = Struct.new(:name, keyword_init: true)             # @Foo
        PathExpr = Struct.new(:segments, keyword_init: true)      # trailer::Catalog::Pages
        Literal = Struct.new(:value, keyword_init: true)          # 42, "str", :Name
        ArrayLit = Struct.new(:values, keyword_init: true)        # [a, b, c]
        BinOp = Struct.new(:op, :left, :right, keyword_init: true) # ==, !=, <, >, <=, >=, +, -, *, /
        UnaryOp = Struct.new(:op, :operand, keyword_init: true)    # !
        LogicalOp = Struct.new(:op, :left, :right, keyword_init: true) # &&, ||
        Placeholder = Struct.new(:text, keyword_init: true)        # raw, unsupported
      end
    end
  end
end
