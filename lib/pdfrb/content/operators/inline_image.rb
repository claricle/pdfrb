# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Inline image operators (s8.9.7). Inline images embed raw image
      # data directly in the content stream, framed by BI ... ID ...
      # EI. They're an alternative to /XObject /Image for one-shot
      # images: smaller overhead per image, no /Resources entry
      # needed, but the bytes live in the content stream so they
      # can't be reused.
      #
      # The Parser detects BI ... ID ... EI and yields a single
      # BeginInlineImage invocation with the parsed image Hash as
      # the operand. The invoke hook calls Processor#inline_image.
      class BeginInlineImage < Base
        class << self
          def name; "BI"; end

          def serialize(serializer, **dict)
            buf = +"BI\n"
            dict.each do |k, v|
              buf << serializer.serialize(k) << " " << serializer.serialize(v) << "\n"
            end
            buf << "ID\n"
            buf
          end

          def invoke(processor, image = nil)
            processor.inline_image(image) if image
          end
        end
        register
      end

      class EndInlineImage < Base
        class << self
          def name; "EI"; end

          def invoke(_processor, *_operands); end
        end
        register
      end
    end
  end
end
