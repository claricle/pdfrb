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
      # The serialise path emits the BI dict, ID marker, raw bytes,
      # and EI marker. The invoke path is intentionally a no-op; the
      # content Parser handles BI/ID/EI as a single bounded block
      # rather than via the operator dispatch table.
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

          def invoke(_processor, *_operands); end
          register
        end
      end

      class EndInlineImage < Base
        class << self
          def name; "EI"; end

          # The byte payload sits between ID and EI. The serializer
          # for inline images writes the payload directly via
          # Canvas#inline_image; this method is here so the registry
          # knows about EI.
          def serialize(_serializer, *_operands)
            "EI\n"
          end

          def invoke(_processor, *_operands); end
          register
        end
      end
    end
  end
end
