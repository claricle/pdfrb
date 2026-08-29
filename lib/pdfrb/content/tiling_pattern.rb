# frozen_string_literal: true

module Pdfrb
  module Content
    # Tiling patterns (ISO 32000-2 §8.7.3). A tiling pattern is a
    # repeating cell that fills an area. Type 1 (constant spacing) and
    # Type 2 (no distortion) are supported.
    #
    # The pattern cell is drawn via a block using the Canvas API.
    # Registered in page Resources under /Pattern.
    class TilingPattern
      PATTERN_TYPE = 1

      attr_reader :paint_type, :tiling_type, :bbox, :x_step, :y_step

      # @param paint_type [Integer] 1 = colored, 2 = uncolored.
      # @param tiling_type [Integer] 1 = constant, 2 = no distortion, 3 = constant spacing + no distortion.
      # @param bbox [Array] bounding box of the pattern cell.
      # @param x_step [Numeric] horizontal repeat distance.
      # @param y_step [Numeric] vertical repeat distance.
      def initialize(paint_type: 1, tiling_type: 1, bbox: [0, 0, 16, 16],
                     x_step: 16, y_step: 16)
        @paint_type = paint_type
        @tiling_type = tiling_type
        @bbox = bbox
        @x_step = x_step
        @y_step = y_step
      end

      # Build the pattern stream and register it in the page's Resources.
      # @param document [Pdfrb::Document]
      # @param page [Pdfrb::Model::Cos::Dictionary] target page.
      # @yield [canvas] block that draws the pattern cell.
      # @return [Symbol] the resource name (e.g. :P1)
      def register_on(document, page)
        pattern_stream = document.add(
          {
            Type: :Pattern,
            PatternType: PATTERN_TYPE,
            PaintType: @paint_type,
            TilingType: @tiling_type,
            BBox: @bbox,
            XStep: @x_step,
            YStep: @y_step,
          },
          type: Pdfrb::Model::Cos::Stream
        )

        if block_given?
          canvas = Pdfrb::Content::Canvas.new(pattern_stream, document: document)
          yield canvas
        end

        ref = pattern_stream.ref
        register_in_resources(document, page, ref)
      end

      private

      def register_in_resources(_document, page, ref)
        resources = page.value[:Resources]
        resources = {} unless resources.is_a?(::Hash)
        pattern_dict = resources[:Pattern] || {}
        name = next_pattern_name(pattern_dict)
        pattern_dict[name] = ref
        resources[:Pattern] = pattern_dict
        page.value[:Resources] = resources
        name
      end

      def next_pattern_name(pattern_dict)
        existing = pattern_dict.keys.map(&:to_s).grep(/\AP\d+\z/).map { |k| k[1..].to_i }
        num = (existing.max || 0) + 1
        :"P#{num}"
      end
    end
  end
end
