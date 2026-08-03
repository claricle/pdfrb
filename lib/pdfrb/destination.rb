# frozen_string_literal: true

module Pdfrb
  # Destinations (ISO 32000-2 §12.3.2). A destination specifies a view
  # of a page: which page, how to fit it in the viewport, and optional
  # position/zoom parameters.
  #
  # Each fit type is a value object that serializes to a PDF destination
  # array: [page_ref /Fit], [page_ref /XYZ x y zoom], etc.
  module Destination
    autoload :Fit, "pdfrb/destination/fit"
  end
end
