# frozen_string_literal: true

module Pdfrb
  class CLI
    module Fonts
      module_function

      def call(path)
        doc = Pdfrb::Document.open(path)
        puts "Fonts:"
        doc.fonts.each { |name, res| puts "  #{res}: #{name}" }
        true
      end
    end
  end
end
