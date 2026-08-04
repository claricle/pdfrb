# frozen_string_literal: true

module Pdfrb
  class CLI
    module Files
      module_function

      def call(path)
        doc = Pdfrb::Document.open(path)
        puts "Embedded files:"
        doc.files.each { |f| puts "  #{f}" }
        true
      end
    end
  end
end
