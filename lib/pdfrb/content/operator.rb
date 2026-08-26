# frozen_string_literal: true

module Pdfrb
  module Content
    # Operator catalogue. Each PDF content operator (`q`, `m`, `Tj`,
    # ...) is implemented by a subclass of +Operator::Base+ that
    # registers itself in +REGISTRY+ at file load.
    #
    # Adding a new operator = adding one subclass + `register`. No
    # switch edits (open/closed). Mirrors the postscript gem's
    # Model::Operators pattern.
    module Operator
      @registry = {}

      # Referenced directly by the Parser for BI ... ID ... EI
      # sequences; the remaining operator classes load via
      # eager_load! / Operator[].
      autoload :BeginInlineImage, "pdfrb/content/operators/inline_image"
      autoload :EndInlineImage, "pdfrb/content/operators/inline_image"

      class << self
        attr_reader :registry

        def register(name, klass)
          @registry[name.to_s] = klass
        end

        def [](name)
          key = name.to_s
          result = @registry[key]
          return result if result

          # Lazy-load on miss: trigger eager_load! which populates
          # the registry, then retry.
          eager_load! unless @eager_loaded
          @registry[key]
        end

        def names
          @registry.keys
        end

        # Force-load all operator implementations so register calls
        # fire and populate the registry. Idempotent.
        def eager_load!
          return if @eager_loaded

          Pdfrb::Content::Operators.constants.each do |c|
            Pdfrb::Content::Operators.const_get(c)
          rescue NameError
            # Skip modules that don't resolve.
          end
          @eager_loaded = true
        end
      end

      # Base class. Subclasses override +name+ and optionally
      # +invoke+ (read-side effect on the Processor) and +serialize+
      # (write-side emit).
      class Base
        class << self
          def name
            raise NotImplementedError, "#{self} must define self.name"
          end

          def register
            Operator.register(self.name, self)
          end

          # Default serialize: join operands with spaces and append
          # the operator keyword.
          def serialize(serializer, *operands)
            prefix = operands.empty? ? +"#{name}\n" : +""
            unless operands.empty?
              prefix << operands.map { |o| serializer.serialize(o) }.join(" ")
              prefix << " #{name}\n"
            end
            prefix
          end

          # Read-side: default no-op. Subclasses override to mutate
          # processor.graphics_state (or do painting / text / etc.).
          def invoke(_processor, *_operands); end
        end
      end

      # Convenience subclass for operators that take no operands and
      # have a fixed serialization.
      class NoArg < Base
        class << self
          def serialize(_serializer, *_operands)
            "#{name}\n"
          end
        end
      end
    end
  end
end
