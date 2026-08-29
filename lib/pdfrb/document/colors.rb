# frozen_string_literal: true

module Pdfrb
  class Document
    # Facade for color space management. Embeds ICC profiles, registers
    # named color spaces in page Resources, and provides lookup.
    class Colors
      attr_reader :document

      def initialize(document)
        @document = document
        @next_cs_number = 1
      end

      # Embed an ICC profile as a stream and return the color space
      # array [/ICCBased <ref>] for use in Resources.
      #
      # @param icc_bytes [String] raw ICC profile bytes.
      # @param alternate [Symbol, nil] fallback color space
      #   (:DeviceRGB, :DeviceCMYK, :DeviceGray, :Lab). Derived from
      #   the profile header if nil.
      # @return [Pdfrb::Model::PdfArray] the [/ICCBased <ref>] array.
      def embed_icc_profile(icc_bytes, alternate: nil)
        profile = Pdfrb::Color::ICCProfile.new(icc_bytes, alternate: alternate)
        stream = document.add(
          { **profile.stream_dictionary_fields,
            Length: profile.raw_data.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = profile.raw_data
        Pdfrb::Model::PdfArray.new([
                                     :ICCBased,
                                     stream.ref,
                                   ])
      end

      # Register a color space in a page's Resources /ColorSpace dict
      # and return the name (e.g. :CS1) for use in content streams.
      #
      # @param page [Pdfrb::Model::Cos::Dictionary] the target page.
      # @param color_space the color space value (name, array, or ref).
      # @return [Symbol] the registered name.
      def register(page, color_space)
        resources = ensure_resources(page)
        cs_dict = resources.value[:ColorSpace]
        cs_dict = ensure_color_space_dict(resources, cs_dict)

        name = cs_name
        cs_dict[name] = color_space
        name
      end

      private

      def ensure_resources(page)
        resources = page.value[:Resources]
        return resources if resources.is_a?(Pdfrb::Model::Cos::Dictionary)

        resources_hash = if resources.is_a?(Pdfrb::Model::Reference)
                           document.object(resources)&.value
                         else
                           resources
                         end
        if resources_hash.nil?
          resources_hash = {}
          page.value[:Resources] = resources_hash
        end
        wrap_resources(page, resources_hash)
      end

      def wrap_resources(page, hash)
        existing = page.value[:Resources]
        return existing if existing.is_a?(Pdfrb::Model::Cos::Dictionary)

        wrapped = Pdfrb::Model::Cos::Dictionary.new(hash)
        page.value[:Resources] = wrapped
        wrapped
      end

      def ensure_color_space_dict(resources, cs_dict)
        return cs_dict if cs_dict.is_a?(::Hash) || cs_dict.is_a?(Pdfrb::Model::Cos::Dictionary)

        cs_hash = {}
        resources.value[:ColorSpace] = cs_hash
        cs_hash
      end

      def cs_name
        name = :"CS#{@next_cs_number}"
        @next_cs_number += 1
        name
      end
    end
  end
end
