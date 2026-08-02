# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Color operators (s8.6). Lowercase sets fill color, uppercase
      # sets stroke color.

      class FillGray < Base
        def self.name; "g"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(fill_color: [:gray, n.to_f])
        end
        register
      end

      class StrokeGray < Base
        def self.name; "G"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(stroke_color: [:gray, n.to_f])
        end
        register
      end

      class FillRGB < Base
        def self.name; "rg"; end
        def self.invoke(processor, r, g, b)
          processor.update_graphics_state(fill_color: [:rgb, r.to_f, g.to_f, b.to_f])
        end
        register
      end

      class StrokeRGB < Base
        def self.name; "RG"; end
        def self.invoke(processor, r, g, b)
          processor.update_graphics_state(stroke_color: [:rgb, r.to_f, g.to_f, b.to_f])
        end
        register
      end

      class FillCMYK < Base
        def self.name; "k"; end
        def self.invoke(processor, c, m, y, k)
          processor.update_graphics_state(fill_color: [:cmyk, c.to_f, m.to_f, y.to_f, k.to_f])
        end
        register
      end

      class StrokeCMYK < Base
        def self.name; "K"; end
        def self.invoke(processor, c, m, y, k)
          processor.update_graphics_state(stroke_color: [:cmyk, c.to_f, m.to_f, y.to_f, k.to_f])
        end
        register
      end

      class SetFillColorSpace < Base
        def self.name; "cs"; end
        def self.invoke(processor, name)
          processor.update_graphics_state(fill_color: [:color_space, name])
        end
        register
      end

      class SetStrokeColorSpace < Base
        def self.name; "CS"; end
        def self.invoke(processor, name)
          processor.update_graphics_state(stroke_color: [:color_space, name])
        end
        register
      end

      class SetFillColor < Base
        def self.name; "sc"; end
        def self.invoke(processor, *components)
          processor.update_graphics_state(fill_color: [:components, components])
        end
        register
      end

      class SetStrokeColor < Base
        def self.name; "SC"; end
        def self.invoke(processor, *components)
          processor.update_graphics_state(stroke_color: [:components, components])
        end
        register
      end

      class SetFillColorN < Base
        def self.name; "scn"; end
        def self.invoke(processor, *components)
          processor.update_graphics_state(fill_color: [:components_n, components])
        end
        register
      end

      class SetStrokeColorN < Base
        def self.name; "SCN"; end
        def self.invoke(processor, *components)
          processor.update_graphics_state(stroke_color: [:components_n, components])
        end
        register
      end
    end
  end
end
