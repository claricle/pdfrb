# frozen_string_literal: true

module Pdfrb
  # Content-stream layer. Pages and Form XObjects carry a content
  # stream: a sequence of `operands operator` instructions that draw
  # graphics and text. This layer parses, walks, and emits those
  # streams.
  #
  # Architecture mirrors HexaPDF::Content:
  #   * +Tokenizer+ from Source layer produces tokens (content
  #     streams use the same PDF object syntax as COS values).
  #   * +Content::Parser+ groups operands + operator into invocations.
  #   * +Content::Operator::Base+ subclasses implement each PDF
  #     operator (one file per category — open/closed via `register`).
  #   * +Content::Processor+ walks a stream, invoking operators
  #     against a +GraphicsState+ (with a stack for `q`/`Q`).
  #   * +Content::Canvas+ is the high-level drawing API on a Stream.
  module Content
    autoload :GraphicsState, "pdfrb/content/graphics_state"
    autoload :Operator, "pdfrb/content/operator"
    autoload :Parser, "pdfrb/content/parser"
    autoload :Processor, "pdfrb/content/processor"
    autoload :Canvas, "pdfrb/content/canvas"
    autoload :GraphicObject, "pdfrb/content/graphic_object"
  end
end

# Eager-load operator subclasses so they self-register in the
# Operator::REGISTRY. (Each file calls Operator.register at the bottom.)
require "pdfrb/content/operators/general"
require "pdfrb/content/operators/path"
require "pdfrb/content/operators/painting"
require "pdfrb/content/operators/text_state"
require "pdfrb/content/operators/text_positioning"
require "pdfrb/content/operators/text_showing"
require "pdfrb/content/operators/color"
require "pdfrb/content/operators/graphics_state_params"
require "pdfrb/content/operators/marked_content"
