# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Path construction operators (s8.5).

      class MoveTo < Base
        def self.name; "m"; end
        def self.invoke(processor, x, y)
          processor.path_move_to(x.to_f, y.to_f)
        end
        register
      end

      class LineTo < Base
        def self.name; "l"; end
        def self.invoke(processor, x, y)
          processor.path_line_to(x.to_f, y.to_f)
        end
        register
      end

      class CurveTo < Base
        def self.name; "c"; end
        def self.invoke(processor, x1, y1, x2, y2, x3, y3)
          processor.path_curve_to([x1.to_f, y1.to_f], [x2.to_f, y2.to_f], [x3.to_f, y3.to_f])
        end
        register
      end

      class CurveToFirstReflected < Base
        def self.name; "v"; end
        def self.invoke(processor, x2, y2, x3, y3)
          processor.path_curve_to(nil, [x2.to_f, y2.to_f], [x3.to_f, y3.to_f])
        end
        register
      end

      class CurveToLastEqual < Base
        def self.name; "y"; end
        def self.invoke(processor, x1, y1, x3, y3)
          processor.path_curve_to([x1.to_f, y1.to_f], [x3.to_f, y3.to_f], [x3.to_f, y3.to_f])
        end
        register
      end

      class ClosePath < NoArg
        def self.name; "h"; end
        def self.invoke(processor, *); processor.path_close; end
        register
      end

      class Rectangle < Base
        def self.name; "re"; end
        def self.invoke(processor, x, y, width, height)
          processor.path_rectangle(x.to_f, y.to_f, width.to_f, height.to_f)
        end
        register
      end

      class EndPath < NoArg
        def self.name; "n"; end
        def self.invoke(processor, *); processor.path_end; end
        register
      end
    end
  end
end
