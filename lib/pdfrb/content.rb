# frozen_string_literal: true

module Pdfrb
  module Content
    autoload :GraphicsState, "pdfrb/content/graphics_state"
    autoload :Operator, "pdfrb/content/operator"
    autoload :Parser, "pdfrb/content/parser"
    autoload :Processor, "pdfrb/content/processor"
    autoload :ColorSpace, "pdfrb/content/color_space"
    autoload :TransformationMatrix, "pdfrb/content/transformation_matrix"
    autoload :Canvas, "pdfrb/content/canvas"
    autoload :GraphicObject, "pdfrb/content/graphic_object"
    autoload :Operators, "pdfrb/content/operators"
    autoload :TilingPattern, "pdfrb/content/tiling_pattern"
    autoload :HiddenTextDetector, "pdfrb/content/hidden_text_detector"
    autoload :SmartTextExtractor, "pdfrb/content/smart_text_extractor"
    autoload :Shading, "pdfrb/content/shading"
  end
end
