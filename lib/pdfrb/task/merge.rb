# frozen_string_literal: true

module Pdfrb
  module Task
    # Merge multiple source PDFs into a target Document. Each source
    # page is deep-copied via +Importer+ (which preserves resources,
    # fonts, content streams). Source documents remain unchanged.
    module Merge
      module_function

      def call(target, *sources)
        sources.each { |src| import_all_pages(target, src) }
        target
      end

      def import_all_pages(target, source)
        importer = Pdfrb::Importer.new(target)
        source.pages.each do |page|
          new_value = importer.import(page.value, source)
          new_value[:Parent] = parent_ref(target)
          new_page = target.add(new_value, type: Pdfrb::Model::Type::Page)
          kids = pages_root(target).value[:Kids]
          kids << new_page.ref
          pages_root(target).value[:Count] = (pages_root(target).value[:Count] || 0) + 1
        end
      end
      private_class_method :import_all_pages

      def pages_root(target)
        ref = target.catalog.value[:Pages] || begin
          root = target.add({ Type: :Pages, Kids: [], Count: 0 },
                            type: Pdfrb::Model::Type::PageTreeNode)
          target.catalog.value[:Pages] = root.ref
          target.catalog.value[:Pages]
        end
        target.object(ref)
      end
      private_class_method :pages_root

      def parent_ref(target)
        root = pages_root(target)
        root.ref
      end
      private_class_method :parent_ref
    end
  end
end
