# frozen_string_literal: true

module Pdfrb
  module Task
    # Walk each page's /Resources/XObject for Image XObjects and yield
    # (page, name, image_stream). Returns a flat list when no block.
    module ExtractImages
      module_function

      ImageInfo = Struct.new(:page_index, :name, :stream,
                             :width, :height, :filter, keyword_init: true)

      def call(document)
        results = []
        document.pages.each_with_index do |page, idx|
          xobjects = xobject_map(page, document)
          xobjects&.each do |name, ref|
            stream = document.resolve(ref)
            next unless stream.is_a?(Pdfrb::Model::Cos::Stream)
            next unless stream.value[:Subtype] == :Image

            info = ImageInfo.new(
              page_index: idx,
              name: name.to_s,
              stream: stream,
              width: stream.value[:Width],
              height: stream.value[:Height],
              filter: stream.value[:Filter]
            )
            block_given? ? yield(info) : (results << info)
          end
        end
        block_given? ? document : results
      end

      def xobject_map(page, document)
        # /Resources can be inheritable from a parent Pages node.
        resources = page.value[:Resources]
        if resources.nil?
          parent_ref = page.value[:Parent]
          parent = parent_ref && document.object(parent_ref)
          resources = parent&.value&.dig(:Resources) if parent
        end
        return nil unless resources

        resources = resources.value if resources.is_a?(Pdfrb::Model::Cos::Dictionary)
        resources[:XObject]
      end
      module_function :xobject_map
    end
  end
end
