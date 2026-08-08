# frozen_string_literal: true

module Pdfrb
  # Layout engine (mirrors HexaPDF::Layout). High-level document
  # composition: Frame + Box + Composer. Boxes (text, image, table,
  # list) are placed into Frames which represent page regions. Content
  # flows across pages when a Frame fills up.
  module Layout
    autoload :Frame, "pdfrb/layout/frame"
    autoload :Style, "pdfrb/layout/style"
    autoload :NumericRefinements, "pdfrb/layout/numeric_refinements"
    autoload :Box, "pdfrb/layout/box"
    autoload :ContainerBox, "pdfrb/layout/container_box"
    autoload :TextBox, "pdfrb/layout/text_box"
    autoload :ImageBox, "pdfrb/layout/image_box"
    autoload :ListBox, "pdfrb/layout/list_box"
    autoload :TableBox, "pdfrb/layout/table_box"
    autoload :ColumnBox, "pdfrb/layout/column_box"
    autoload :InlineBox, "pdfrb/layout/inline_box"
    autoload :BoxFitter, "pdfrb/layout/box_fitter"
    autoload :PageStyle, "pdfrb/layout/page_style"
    autoload :TextLayouter, "pdfrb/layout/text_layouter"
    autoload :TextFragment, "pdfrb/layout/text_fragment"
    autoload :Line, "pdfrb/layout/line"
    autoload :Bidi, "pdfrb/layout/bidi"
    autoload :RomanNumeral, "pdfrb/layout/list_box"
  end
end
