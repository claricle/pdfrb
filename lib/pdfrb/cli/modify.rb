# frozen_string_literal: true
module Pdfrb; class CLI
  module Umodify
    module_function
    def call(path, **opts)
      doc = Pdfrb::Document.open(path)
      yield doc if block_given?
      output = opts[:output] || path
      doc.write(output)
      puts "Processed: #{output}"
      true
    end
  end
end; end
