# frozen_string_literal: true

module Pdfrb
  class Document
    # Gradient shading patterns facade. Creates Type 2 (axial) and
    # Type 3 (radial) shading dictionaries and registers them in page
    # /Resources /Shading.
    #
    # For 2-stop gradients, uses a Type 2 ExponentialInterpolation
    # function (/FunctionType 2). For multi-stop, chains Type 3
    # StitchingFunction.
    class Shadings
      attr_reader :document, :registry

      def initialize(document)
        @document = document
        @registry = {}
        @next_id = 1
      end

      # Add an axial (linear) gradient.
      # @param from [Array(Numeric, Numeric)] start point [x, y].
      # @param to [Array(Numeric, Numeric)] end point [x, y].
      # @param stops [Array<Array>] gradient stops:
      #   [[offset, [color_family, *values]], ...]
      # @param extend [Array<Boolean, Boolean>] extend before/after.
      # @return [Symbol] shading resource name (e.g., :Sh1).
      def add_axial(from:, to:, stops:, extend: [true, true])
        color_space = stops_to_color_values(stops.first || [0, [:gray, 0]])[0]
        name = next_name

        function = build_gradient_function(stops, color_space)

        shading = document.add(
          {
            ShadingType: 2,
            ColorSpace: color_space,
            Coords: Pdfrb::Model::PdfArray.new([*from, *to]),
            Function: function,
            Extend: Pdfrb::Model::PdfArray.new(extend),
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        register(name, shading)
        name
      end

      # Add a radial gradient.
      # @param from [Array(Numeric, Numeric, Numeric)] [cx, cy, radius].
      # @param to [Array(Numeric, Numeric, Numeric)] [cx, cy, radius].
      # @param stops [Array<Array>] same format as axial.
      # @param extend [Array<Boolean, Boolean>] extend before/after.
      # @return [Symbol] shading resource name.
      def add_radial(from:, to:, stops:, extend: [true, true])
        color_space = stops_to_color_values(stops.first || [0, [:gray, 0]])[0]
        name = next_name

        function = build_gradient_function(stops, color_space)

        shading = document.add(
          {
            ShadingType: 3,
            ColorSpace: color_space,
            Coords: Pdfrb::Model::PdfArray.new([*from, *to]),
            Function: function,
            Extend: Pdfrb::Model::PdfArray.new(extend),
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        register(name, shading)
        name
      end

      def [](name)
        @registry[name]
      end

      def each(&block)
        return enum_for(:each) unless block

        @registry.each(&block)
        self
      end

      private

      def build_gradient_function(stops, color_space)
        return build_exponential_function(nil, nil, color_space) if stops.empty?

        if stops.length == 2
          _, c0 = stops_to_color_values(stops[0])
          _, c1 = stops_to_color_values(stops[1])
          build_exponential_function(c0, c1, color_space)
        else
          build_stitching_function(stops, color_space)
        end
      end

      def build_stitching_function(stops, color_space)
        functions = stops.each_cons(2).map do |s0, s1|
          _, c0 = stops_to_color_values(s0)
          _, c1 = stops_to_color_values(s1)
          build_exponential_function(c0, c1, color_space)
        end

        bounds = stops[1..-2].map { |s| s[0] }

        document.add(
          {
            FunctionType: 3,
            Domain: Pdfrb::Model::PdfArray.new([0, 1]),
            Functions: functions.map { |f| Pdfrb::Model::Reference.new(f.oid, f.gen) },
            Bounds: Pdfrb::Model::PdfArray.new(bounds),
            Encode: Pdfrb::Model::PdfArray.new(stops.each_cons(2).map { [0, 1] }.flatten),
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
      end

      def stops_to_color_values(stop)
        family, *values = stop[1]
        cs = case family.to_sym
             when :rgb then :DeviceRGB
             when :cmyk then :DeviceCMYK
             else :DeviceGray
             end
        [cs, values]
      end

      def build_exponential_function(c0, c1, _color_space)
        document.add(
          {
            FunctionType: 2,
            Domain: Pdfrb::Model::PdfArray.new([0, 1]),
            C0: Pdfrb::Model::PdfArray.new(c0),
            C1: Pdfrb::Model::PdfArray.new(c1),
            N: 1,
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
      end

      def register(name, shading_obj)
        @registry[name] = shading_obj
        document.catalog
        # Attach to the page-tree root so every page inherits it
        # (s7.7.3.2); the Catalog has no /Resources key in PDF.
        root = document.pages.pages_root
        root.value[:Resources] ||= {}
        root.value[:Resources][:Shading] ||= {}
        root.value[:Resources][:Shading][name] =
          Pdfrb::Model::Reference.new(shading_obj.oid, shading_obj.gen)
      end

      def next_name
        name = :"Sh#{@next_id}"
        @next_id += 1
        name
      end
    end
  end
end
