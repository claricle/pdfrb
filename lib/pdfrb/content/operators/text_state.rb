# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Text-state operators (s9.3). Each updates a slot in the
      # Processor's current TextState.

      class CharSpacing < Base
        def self.name; "Tc"; end
        def self.invoke(processor, n)
          processor.update_text_state(char_spacing: n.to_f)
        end
        register
      end

      class WordSpacing < Base
        def self.name; "Tw"; end
        def self.invoke(processor, n)
          processor.update_text_state(word_spacing: n.to_f)
        end
        register
      end

      class HorizontalScaling < Base
        def self.name; "Tz"; end
        def self.invoke(processor, n)
          processor.update_text_state(horizontal_scaling: n.to_f)
        end
        register
      end

      class Leading < Base
        def self.name; "TL"; end
        def self.invoke(processor, n)
          processor.update_text_state(leading: n.to_f)
        end
        register
      end

      class Font < Base
        def self.name; "Tf"; end
        def self.invoke(processor, name, size)
          processor.update_text_state(font_name: name, font_size: size.to_f)
        end
        register
      end

      class RenderingMode < Base
        def self.name; "Tr"; end
        def self.invoke(processor, mode)
          processor.update_text_state(rendering_mode: mode.to_i)
        end
        register
      end

      class Rise < Base
        def self.name; "Ts"; end
        def self.invoke(processor, n)
          processor.update_text_state(rise: n.to_f)
        end
        register
      end
    end
  end
end
