# frozen_string_literal: true

module Pdfrb
  module Content
    module Shading
      # Base shading builder. Subclasses set +shading_type+ and
      # +shading_fields+. Creates a shading dict and registers it
      # in the page's /Resources /Shading sub-dict.
      class Base
        attr_reader :color_space

        class << self
          def shading_type
            raise NotImplementedError
          end
        end

        def initialize(color_space: :DeviceGray)
          @color_space = color_space
        end

        # Build the shading dictionary value (a Hash).
        def to_dict
          { ShadingType: self.class.shading_type,
            ColorSpace: @color_space }.merge!(shading_fields)
        end

        # Register this shading on a page and return the resource name.
        # @param document [Pdfrb::Document]
        # @param page [Pdfrb::Model::Cos::Dictionary] target page.
        # @return [Symbol] resource name (e.g. :Sh1)
        def register_on(document, page)
          shading_obj = document.add(to_dict, type: Pdfrb::Model::Cos::Dictionary)
          ref = Pdfrb::Model::Reference.new(shading_obj.oid, shading_obj.gen)
          resources = ensure_resources(document, page)
          shading_dict = resources.value[:Shading]
          if shading_dict.nil?
            shading_dict = {}
            resources.value[:Shading] = shading_dict
          end
          name = next_shading_name(shading_dict)
          shading_dict[name] = ref
          name
        end

        protected

        def shading_fields
          {}
        end

        private

        def ensure_resources(document, page)
          resources = page.value[:Resources]
          return resources if resources.is_a?(Pdfrb::Model::Cos::Dictionary)

          resources_hash = if resources.is_a?(Pdfrb::Model::Reference)
                             document.object(resources)&.value
                           else
                             resources
                           end
          resources_hash ||= {}
          wrapped = Pdfrb::Model::Cos::Dictionary.new(resources_hash)
          page.value[:Resources] = wrapped
          wrapped
        end

        def next_shading_name(shading_dict)
          existing = shading_dict.keys.map(&:to_s).grep(/\ASh\d+\z/).map { |k| k[2..].to_i }
          num = (existing.max || 0) + 1
          :"Sh#{num}"
        end
      end

      # Axial (linear) gradient. ShadingType 2.
      # ISO 32000-2 §8.7.4.5.4.
      class Axial < Base
        attr_reader :start_point, :end_point, :function, :extend

        def initialize(color_space:, start_point:, end_point:,
                       function:, extend: nil)
          super(color_space: color_space)
          @start_point = start_point
          @end_point = end_point
          @function = function
          @extend = extend
        end

        class << self
          def shading_type; 2; end
        end

        protected

        def shading_fields
          fields = {
            Coords: Pdfrb::Model::PdfArray.new([*@start_point, *@end_point]),
            Function: @function,
          }
          fields[:Extend] = Pdfrb::Model::PdfArray.new(@extend) if @extend
          fields
        end
      end

      # Radial gradient. ShadingType 3.
      # ISO 32000-2 §8.7.4.5.3.
      class Radial < Base
        attr_reader :center1, :radius1, :center2, :radius2, :function, :extend

        def initialize(color_space:, center1:, radius1:, center2:, radius2:,
                       function:, extend: nil)
          super(color_space: color_space)
          @center1 = center1
          @radius1 = radius1
          @center2 = center2
          @radius2 = radius2
          @function = function
          @extend = extend
        end

        class << self
          def shading_type; 3; end
        end

        protected

        def shading_fields
          fields = {
            Coords: Pdfrb::Model::PdfArray.new([*@center1, @radius1, *@center2, @radius2]),
            Function: @function,
          }
          fields[:Extend] = Pdfrb::Model::PdfArray.new(@extend) if @extend
          fields
        end
      end
    end
  end
end
