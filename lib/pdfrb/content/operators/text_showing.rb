# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Text-showing operators (s9.4.3). Each invokes a +show_text+
      # hook on the Processor.

      class ShowText < Base
        def self.name; "Tj"; end
        def self.invoke(processor, str)
          processor.show_text(str.to_s)
        end
        register
      end

      class ShowTextWithSpacing < Base
        def self.name; "TJ"; end
        def self.invoke(processor, array)
          processor.show_text_array(array.to_a)
        end
        register
      end

      class MoveToNextLineShowText < Base
        def self.name; "'"; end
        def self.invoke(processor, str)
          leading = processor.graphics_state.text_state.leading
          processor.move_text(0, -leading, set_leading: false)
          processor.show_text(str.to_s)
        end
        register
      end

      class SetSpacingMoveToShowText < Base
        def self.name; "\""; end
        def self.invoke(processor, word_spacing, char_spacing, str)
          processor.update_text_state(word_spacing: word_spacing.to_f,
                                      char_spacing: char_spacing.to_f)
          leading = processor.graphics_state.text_state.leading
          processor.move_text(0, -leading, set_leading: false)
          processor.show_text(str.to_s)
        end
        register
      end
    end
  end
end
