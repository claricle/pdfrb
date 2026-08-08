# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Evaluates a predicate AST against a Context. Returns a Ruby
      # value (typically Boolean for predicates; Integer/String for
      # arithmetic helpers like ArrayLength, FileSize).
      class Evaluator
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def self.call(ast, context)
          new(context).evaluate(ast)
        end

        def evaluate(node)
          return nil if node.nil?

          case node
          when AST::FunctionCall then dispatch_function(node)
          when AST::AtKey then resolve_at_key(node.name)
          when AST::PathExpr then resolve_path(node.segments)
          when AST::Literal then node.value
          when AST::ArrayLit then node.values
          when AST::BinOp then eval_binop(node)
          when AST::UnaryOp then eval_unaryop(node)
          when AST::LogicalOp then eval_logical(node)
          else
            raise Pdfrb::Error, "unknown AST node #{node.class}"
          end
        end

        private

        def dispatch_function(node)
          name = node.name.sub("fn:", "")
          fn = Functions.registry[name]
          if fn.nil?
            raise Pdfrb::ValidationError.new(
              "unknown predicate function fn:#{name}",
              predicate_name: "fn:#{name}"
            )
          end

          args = node.args.map { |a| evaluate(a) }
          fn.call(args, context)
        end

        def resolve_at_key(name)
          return nil unless context.current

          context.current[name.to_sym]
        end

        def resolve_path(segments)
          case segments.first
          when "parent" then walk(context.parent, segments[1..])
          when "trailer" then walk(context.trailer, segments[1..])
          else
            walk(context.current, segments)
          end
        end

        def walk(start, segments)
          cur = start
          segments.each do |seg|
            return nil unless cur.is_a?(Hash)
            next if seg.nil?

            cur = cur[seg.to_sym]
          end
          cur
        end

        def eval_binop(node)
          left = evaluate(node.left)
          right = evaluate(node.right)
          case node.op
          when :== then left == right
          when :"!=" then left != right
          when :< then left.to_f < right.to_f
          when :> then left.to_f > right.to_f
          when :<= then left.to_f <= right.to_f
          when :>= then left.to_f >= right.to_f
          when :+ then left.to_f + right.to_f
          when :- then left.to_f - right.to_f
          when :* then left.to_f * right.to_f
          when :/ then left.to_f / right.to_f
          when :% then left.to_i % right.to_i
          end
        end

        def eval_unaryop(node)
          case node.op
          when :! then !evaluate(node.operand)
          end
        end

        def eval_logical(node)
          left = evaluate(node.left)
          case node.op
          when :"&&" then left && evaluate(node.right)
          when :"||" then left || evaluate(node.right)
          end
        end
      end
    end
  end
end
