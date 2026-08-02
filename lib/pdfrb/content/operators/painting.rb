# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Path painting operators (s8.5.3). Each calls a +paint_path+
      # hook on the Processor with the right (fill, stroke, close)
      # flag tuple so renderers can dispatch one method.

      class Stroke < NoArg
        def self.name; "S"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: false, stroke: true, close: false, rule: :nonzero)
        end
        register
      end

      class CloseAndStroke < NoArg
        def self.name; "s"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: false, stroke: true, close: true, rule: :nonzero)
        end
        register
      end

      class FillNonZero < NoArg
        def self.name; "f"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: false, close: false, rule: :nonzero)
        end
        register
      end

      # /F is a deprecated alias of /f — keep it in the registry for
      # round-trip fidelity when reading old PDFs.
      class FillDeprecatedAlias < FillNonZero
        def self.name; "F"; end
        register
      end

      class FillEvenOdd < NoArg
        def self.name; "f*"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: false, close: false, rule: :even_odd)
        end
        register
      end

      class FillStrokeNonZero < NoArg
        def self.name; "B"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: true, close: false, rule: :nonzero)
        end
        register
      end

      class FillStrokeEvenOdd < NoArg
        def self.name; "B*"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: true, close: false, rule: :even_odd)
        end
        register
      end

      class CloseFillStrokeNonZero < NoArg
        def self.name; "b"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: true, close: true, rule: :nonzero)
        end
        register
      end

      class CloseFillStrokeEvenOdd < NoArg
        def self.name; "b*"; end
        def self.invoke(processor, *)
          processor.paint_path(fill: true, stroke: true, close: true, rule: :even_odd)
        end
        register
      end
    end
  end
end
