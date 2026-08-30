# frozen_string_literal: true

module Pdfrb
  # PDF header version comparisons (ISO 32000-2, s7.2). Version strings
  # are dot-separated numerics ("1.4", "2.0"); comparison is
  # numeric-per-component, never lexical ("1.10" > "1.9").
  module PdfVersion
    module_function

    # @return [Integer] -1, 0, or 1 as +a+ is earlier, equal, or later
    #   than +b+.
    def compare(a, b)
      aa = a.to_s.split(".").map(&:to_i)
      bb = b.to_s.split(".").map(&:to_i)
      (aa <=> bb) || 0
    end

    # @return [Boolean] whether +version+ meets or exceeds +minimum+.
    def at_least?(version, minimum)
      compare(version, minimum) >= 0
    end
  end
end
