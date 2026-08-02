# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # General graphics-state operators (s8.4.4): q Q cm BT ET.
      # `q`/`Q` push/pop the graphics-state stack on the Processor.
      # `cm` concatenates a matrix onto the CTM.
      # `BT`/`ET` begin/end a text object (reset text + line matrices).

      class SaveGraphicsState < NoArg
        def self.name; "q"; end
        def self.invoke(processor, *); processor.push_graphics_state; end
        register
      end

      class RestoreGraphicsState < NoArg
        def self.name; "Q"; end
        def self.invoke(processor, *); processor.pop_graphics_state; end
        register
      end

      class ConcatMatrix < Base
        def self.name; "cm"; end
        def self.invoke(processor, a, b, c, d, e, f)
          m = Pdfrb::Model::Matrix.new(a, b, c, d, e, f)
          processor.update_graphics_state(ctm: m * processor.graphics_state.ctm)
        end
        register
      end

      class BeginText < NoArg
        def self.name; "BT"; end
        def self.invoke(processor, *)
          ts = processor.graphics_state.text_state.with(
            text_matrix: Pdfrb::Model::Matrix.identity,
            line_matrix: Pdfrb::Model::Matrix.identity
          )
          processor.update_graphics_state(text_state: ts)
        end
        register
      end

      class EndText < NoArg
        def self.name; "ET"; end
        register
      end
    end
  end
end
