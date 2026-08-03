# frozen_string_literal: true

module Pdfrb
  module Content
    autoload :GraphicsState, "pdfrb/content/graphics_state"
    autoload :Operator, "pdfrb/content/operator"
    autoload :Parser, "pdfrb/content/parser"
    autoload :Processor, "pdfrb/content/processor"
    autoload :Canvas, "pdfrb/content/canvas"
    autoload :GraphicObject, "pdfrb/content/graphic_object"
    autoload :TilingPattern, "pdfrb/content/tiling_pattern"
    autoload :HiddenTextDetector, "pdfrb/content/hidden_text_detector"
    autoload :Shading, "pdfrb/content/shading"
  end
end

require "pdfrb/content/operators/general"
require "pdfrb/content/operators/path"
require "pdfrb/content/operators/painting"
require "pdfrb/content/operators/text_state"
require "pdfrb/content/operators/text_positioning"
require "pdfrb/content/operators/text_showing"
require "pdfrb/content/operators/color"
require "pdfrb/content/operators/graphics_state_params"
require "pdfrb/content/operators/marked_content"
require "pdfrb/content/operators/clipping"
