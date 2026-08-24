# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Printer-mark annotation (s12.5.6.17). Marks page for trimming,
      # registration, etc.
      class PrinterMarkAnnotation < Annotation
        arlington_object "AnnotPrinterMark"
        def mark_subtype; self[:MN]; end
      end

      # PrinterMark appearance dictionary (s14.11.4): N/R/D states
      # mapping to appearance streams.
      class AppearancePrinterMarkDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "AppearancePrinterMark"

        def normal; self[:N]; end
        def rollover; self[:R]; end
        def down; self[:D]; end
      end
    end
  end
end
