# frozen_string_literal: true

module Pdfrb
  class CLI
    module Images
      module_function

      def call(path, output_dir: nil)
        doc = Pdfrb::Document.open(path)
        output_dir ||= File.dirname(path)
        count = 0
        doc.pages.each_with_index do |page, pn|
          res = page.value[:Resources]
          next unless res
          xo = res[:XObject] || res.value[:XObject]
          next unless xo
          xo = xo.value if xo.is_a?(Pdfrb::Model::Cos::Dictionary)
          xo&.each do |name, ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? doc.object(ref) : ref
            next unless obj&.value&.[](:Subtype) == :Image
            count += 1
            data = obj.stream || ""
            File.binwrite(File.join(output_dir, "page#{pn + 1}_#{name}.raw"), data)
          end
        end
        puts "Extracted #{count} images"
        true
      end
    end
  end
end
