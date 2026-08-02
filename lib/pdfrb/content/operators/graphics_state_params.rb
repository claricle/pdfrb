# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Graphics-state parameter operators (s8.4.4 minus q/Q/cm which
      # live in operators/general.rb). These update the named slot on
      # the current GraphicsState.

      class LineWidth < Base
        def self.name; "w"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(line_width: n.to_f)
        end
        register
      end

      class LineCap < Base
        def self.name; "J"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(line_cap: n.to_i)
        end
        register
      end

      class LineJoin < Base
        def self.name; "j"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(line_join: n.to_i)
        end
        register
      end

      class MiterLimit < Base
        def self.name; "M"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(miter_limit: n.to_f)
        end
        register
      end

      class DashPattern < Base
        def self.name; "d"; end
        def self.invoke(processor, array, phase)
          processor.update_graphics_state(dash_pattern: [array.to_a, phase.to_i])
        end
        register
      end

      class RenderingIntent < Base
        def self.name; "ri"; end
        def self.invoke(processor, name)
          processor.update_graphics_state(blend_mode: name)
        end
        register
      end

      class Flatness < Base
        def self.name; "i"; end
        def self.invoke(processor, n)
          processor.update_graphics_state(flatness: n.to_i)
        end
        register
      end

      # `gs` applies a named ExtGState dictionary. Lookup happens via
      # the document; fields in the named dict replace matching state
      # slots. We delegate to a +apply_extgstate+ hook on the Processor.
      class ApplyExtGState < Base
        def self.name; "gs"; end
        def self.invoke(processor, name)
          processor.apply_extgstate(name)
        end
        register
      end
    end
  end
end
