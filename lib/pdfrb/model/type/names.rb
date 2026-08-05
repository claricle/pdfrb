# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Names dictionary (s7.9.6) — top-level name-tree roots for
      # /Dests, /AP, /JavaScript, /Pages, /Templates, /URLS,
      # /EmbeddedFiles, /AlternatePresentations, /Renditions.
      class Names < Pdfrb::Model::Cos::Dictionary
        arlington_object "Name"
        register_type :Names

        def destinations; self[:Dests]; end
        def ap; self[:AP]; end
        def javascript; self[:JavaScript]; end
        def pages; self[:Pages]; end
        def templates; self[:Templates]; end
        def urls; self[:URLS]; end
        def embedded_files; self[:EmbeddedFiles]; end
        def alternate_presentations; self[:AlternatePresentations]; end
        def renditions; self[:Renditions]; end

        def has_embedded_files?
          !!embedded_files
        end

        def has_javascript?
          !!javascript
        end

        def has_destinations?
          !!destinations
        end

        def each_embedded_file
          return enum_for(:each_embedded_file) unless block_given?
          return unless embedded_files && document

          walk_name_tree(embedded_files) { |name, ref| yield name, ref }
        end

        private

        def walk_name_tree(node_ref, &block)
          node = node_ref.is_a?(Pdfrb::Model::Reference) && document ?
                   document.object(node_ref) : node_ref
          return unless node

          if node[:Names]
            arr = node[:Names]
            arr = arr.is_a?(Pdfrb::Model::PdfArray) ? arr.to_a : arr
            arr.each_slice(2) { |name, ref| yield name, ref }
          elsif node[:Kids]
            arr = node[:Kids]
            arr = arr.is_a?(Pdfrb::Model::PdfArray) ? arr.to_a : arr
            arr.each { |kid| walk_name_tree(kid, &block) }
          end
        end
      end
    end
  end
end
