# frozen_string_literal: true

module Pdfrb
  module Content
    # High-level shape primitives. Each is a small value object with
    # a +draw(canvas)+ method that emits the right path operators.
    # Adding a new shape = adding one class + (optionally) registering
    # it for the Canvas DSL.
    module GraphicObject
      autoload :Arc, "pdfrb/content/graphic_object/arc"
      autoload :Polyline, "pdfrb/content/graphic_object/polyline"
      autoload :Rectangle, "pdfrb/content/graphic_object/rectangle"
      autoload :Curve, "pdfrb/content/graphic_object/curve"
    end
  end
end
