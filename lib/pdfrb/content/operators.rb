# frozen_string_literal: true

module Pdfrb
  module Content
    # Operator implementation files. Each file defines one or more
    # Operator::Base subclasses that register themselves on load.
    # Eager loading is triggered by Operator.eager_load!.
    module Operators
      autoload :General, "pdfrb/content/operators/general"
      autoload :Path, "pdfrb/content/operators/path"
      autoload :Painting, "pdfrb/content/operators/painting"
      autoload :TextState, "pdfrb/content/operators/text_state"
      autoload :TextPositioning, "pdfrb/content/operators/text_positioning"
      autoload :TextShowing, "pdfrb/content/operators/text_showing"
      autoload :Color, "pdfrb/content/operators/color"
      autoload :GraphicsStateParams, "pdfrb/content/operators/graphics_state_params"
      autoload :MarkedContent, "pdfrb/content/operators/marked_content"
      autoload :Clipping, "pdfrb/content/operators/clipping"
    end
  end
end
