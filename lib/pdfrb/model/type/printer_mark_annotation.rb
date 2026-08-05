# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Printer-mark annotation (s12.5.6.17). Marks page for trimming,
      # registration, etc.
      class PrinterMarkAnnotation < Annotation
        def mark_subtype; self[:MN]; end
      end
    end
  end
end
