# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Text-positioning operators (s9.4.2). Update text_matrix and
      # line_matrix inside the current TextState.

      class TextTranslate < Base
        def self.name; "Td"; end
        def self.invoke(processor, tx, ty)
          processor.move_text(tx.to_f, ty.to_f, set_leading: false)
        end
        register
      end

      class TextTranslateSetLeading < Base
        def self.name; "TD"; end
        def self.invoke(processor, tx, ty)
          processor.move_text(tx.to_f, ty.to_f, set_leading: true, neg_leading: true)
        end
        register
      end

      class SetTextMatrix < Base
        def self.name; "Tm"; end
        def self.invoke(processor, a, b, c, d, e, f)
          m = Pdfrb::Model::Matrix.new(a, b, c, d, e, f)
          processor.set_text_matrix(m)
        end
        register
      end

      class NextLine < NoArg
        def self.name; "T*"; end
        def self.invoke(processor, *)
          leading = processor.graphics_state.text_state.leading
          processor.move_text(0, -leading, set_leading: false)
        end
        register
      end
    end
  end
end
