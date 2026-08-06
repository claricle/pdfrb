# frozen_string_literal: true

module Pdfrb
  module Layout
    # Refinements on Numeric to convert CSS-style units to PDF points.
    #
    # Usage:
    #   using Pdfrb::Layout::NumericRefinements
    #   2.cm   # => 56.6929...
    #   1.inch # => 72.0
    module NumericRefinements
      PT_PER_INCH = 72.0
      PT_PER_CM = PT_PER_INCH / 2.54
      PT_PER_MM = PT_PER_CM / 10.0

      refine Numeric do
        def pt
          to_f
        end

        def cm
          to_f * PT_PER_CM
        end

        def mm
          to_f * PT_PER_MM
        end

        def inch
          to_f * PT_PER_INCH
        end

        alias inches inch

        def pixel(dpi: 96.0)
          to_f * (PT_PER_INCH / dpi)
        end

        alias px pixel
      end
    end
  end
end
