# frozen_string_literal: true

module Pdfrb
  module Image
    # Read-only metadata extractor for embedded image XObjects. Used
    # by Task::Optimize to find downsampling candidates and by callers
    # that need to know what's in a document without re-parsing every
    # stream.
    module Audit
      ImageInfo = Struct.new(
        :oid, :width, :height, :bits_per_component, :color_space,
        :filter_name, :decoded_bytesize, :stream_bytesize, :smask_oid,
        keyword_init: true
      )

      module_function

      # Enumerate every image XObject in +document+. Yields an
      # ImageInfo per image; returns an Enumerator if no block given.
      def each_image(document)
        return enum_for(:each_image, document) unless block_given?

        document.each_indirect_object do |obj|
          next unless image_xobject?(obj)

          yield info_for(obj)
        end
      end

      # Return an Array of all image infos (mirror of #each_image).
      def all(document)
        each_image(document).to_a
      end

      # Find images whose pixel count exceeds +target_pixels+. Useful
      # for spotting oversized images worth downsampling. Returns an
      # Array of ImageInfo.
      def oversized(document, target_pixels:)
        all(document).select do |info|
          (info.width || 0) * (info.height || 0) > target_pixels
        end
      end

      def image_xobject?(obj)
        return false unless obj.is_a?(Pdfrb::Model::Cos::Stream)

        obj.value[:Type] == :XObject && obj.value[:Subtype] == :Image
      end

      def info_for(image)
        ImageInfo.new(
          oid: image.oid,
          width: image.value[:Width],
          height: image.value[:Height],
          bits_per_component: image.value[:BitsPerComponent],
          color_space: image.value[:ColorSpace],
          filter_name: image.value[:Filter],
          decoded_bytesize: decoded_size(image),
          stream_bytesize: image.stream&.bytesize || 0,
          smask_oid: smask_oid(image)
        )
      end

      def decoded_size(image)
        w = image.value[:Width]
        h = image.value[:Height]
        bpc = image.value[:BitsPerComponent] || 8
        return nil unless w && h

        channels = channels_for(image.value[:ColorSpace])
        (w * h * channels * bpc) / 8
      end

      def channels_for(color_space)
        case color_space
        when :DeviceGray, :CalGray, :Indexed then 1
        when :DeviceCMYK then 4
        else
          # :DeviceRGB, :CalRGB, :Lab, nil, and ICCBased (default to
          # 3 channels when we can't introspect the profile) all share
          # this branch.
          3
        end
      end

      def smask_oid(image)
        smask = image.value[:SMask]
        return nil unless smask.is_a?(Pdfrb::Model::Reference)

        smask.oid
      end
    end
  end
end
