# frozen_string_literal: true

module Pdfrb
  class CLI
    module Split
      module_function

      def call(path, output_dir: nil)
        doc = Pdfrb::Document.open(path)
        output_dir ||= File.dirname(path)
        basename = File.basename(path, ".pdf")
        doc.pages.each_with_index do |page, i|
          single = Pdfrb::Document.new
          single.pages.add(media_box: page.media_box)
          single.write(File.join(output_dir, "#{basename}_#{i + 1}.pdf"))
        end
        true
      end
    end
  end
end
