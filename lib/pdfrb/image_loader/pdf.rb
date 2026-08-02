# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    # PDF image loader. Imports a page from another PDF document as
    # a Form XObject, suitable for embedding via the +Do+ operator
    # or the canvas +image+ method (TODO 95 enhancement).
    module PDF
      module_function

      def call(document, io, page: 0, **_opts)
        source_doc = io.is_a?(Pdfrb::Document) ? io : Pdfrb::Document.open(io)
        source_page = source_doc.pages[page]
        return nil unless source_page

        importer = Pdfrb::Importer.new(document)
        imported_value = importer.import(source_page.value, source_doc)
        imported_value.delete(:Parent)
        imported_value[:Type] = :XObject
        imported_value[:Subtype] = :Form
        imported_value[:BBox] ||= imported_value[:MediaBox] || [0, 0, 612, 792]

        form = document.add(imported_value, type: Pdfrb::Model::Type::XObjectForm)
        form
      end
    end
  end
end
