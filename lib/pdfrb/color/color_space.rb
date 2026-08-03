# frozen_string_literal: true

# rubocop:disable Lint/MissingSuper
module Pdfrb
  module Color
    # Color space value objects (ISO 32000-2 §8.6). Each color space
    # knows how to serialize to its PDF representation (a name for
    # device spaces, an array for CIE-based and special spaces).
    #
    # Hierarchy:
    #   Base
    #     Device (DeviceGray, DeviceRGB, DeviceCMYK)
    #     CIEBased (CalGray, CalRGB, Lab, ICCBased)
    #     Special (Indexed, Separation, DeviceN, Pattern)
    #
    # OCP: new color space = subclass + register_as.
    class ColorSpace
      class << self
        def registry
          @registry ||= {}
        end

        def register(name, klass)
          registry[name.to_sym] = klass
        end

        def [](name)
          registry[name.to_sym]
        end

        def names
          registry.keys
        end

        # Subclass hook: the PDF name or array-head symbol.
        def pdf_name
          raise NotImplementedError
        end

        # Register this class under its pdf_name.
        def register_as(name = pdf_name)
          ColorSpace.register(name, self)
          self
        end
      end
    end

    # Device color spaces — simple names, no parameters.
    class DeviceColorSpace < ColorSpace
      def to_pdf
        self.class.pdf_name
      end
    end

    class DeviceGray < DeviceColorSpace
      class << self
        def pdf_name; :DeviceGray; end
      end
      register_as
    end

    class DeviceRGB < DeviceColorSpace
      class << self
        def pdf_name; :DeviceRGB; end
      end
      register_as
    end

    class DeviceCMYK < DeviceColorSpace
      class << self
        def pdf_name; :DeviceCMYK; end
      end
      register_as
    end

    # CIE-based color spaces — arrays with calibration parameters.
    class CIEBasedColorSpace < ColorSpace
      def to_pdf
        Pdfrb::Model::PdfArray.new([self.class.pdf_name, parameters_array].compact.flatten)
      end

      def parameters_array
        []
      end
    end

    class CalGray < CIEBasedColorSpace
      attr_reader :white_point, :black_point, :gamma

      def initialize(white_point:, black_point: nil, gamma: nil)
        @white_point = white_point
        @black_point = black_point
        @gamma = gamma
      end

      class << self
        def pdf_name; :CalGray; end
      end

      def parameters_array
        dict = { WhitePoint: Pdfrb::Model::PdfArray.new(@white_point) }
        dict[:BlackPoint] = Pdfrb::Model::PdfArray.new(@black_point) if @black_point
        dict[:Gamma] = @gamma if @gamma
        dict
      end
      register_as
    end

    class CalRGB < CIEBasedColorSpace
      attr_reader :white_point, :gamma, :matrix, :black_point

      def initialize(white_point:, gamma: nil, matrix: nil, black_point: nil)
        @white_point = white_point
        @gamma = gamma
        @matrix = matrix
        @black_point = black_point
      end

      class << self
        def pdf_name; :CalRGB; end
      end

      def parameters_array
        dict = { WhitePoint: Pdfrb::Model::PdfArray.new(@white_point) }
        dict[:Gamma] = Pdfrb::Model::PdfArray.new(@gamma) if @gamma
        dict[:Matrix] = Pdfrb::Model::PdfArray.new(@matrix) if @matrix
        dict[:BlackPoint] = Pdfrb::Model::PdfArray.new(@black_point) if @black_point
        dict
      end
      register_as
    end

    class Lab < CIEBasedColorSpace
      attr_reader :white_point, :black_point, :range

      def initialize(white_point:, black_point: nil, range: nil)
        @white_point = white_point
        @black_point = black_point
        @range = range
      end

      class << self
        def pdf_name; :Lab; end
      end

      def parameters_array
        dict = { WhitePoint: Pdfrb::Model::PdfArray.new(@white_point) }
        dict[:BlackPoint] = Pdfrb::Model::PdfArray.new(@black_point) if @black_point
        dict[:Range] = Pdfrb::Model::PdfArray.new(@range) if @range
        dict
      end
      register_as
    end

    # ICCBased is special — references an ICC profile stream.
    # Delegates to Pdfrb::Color::ICCProfile for stream creation.
    class ICCBased < CIEBasedColorSpace
      attr_reader :icc_stream_ref

      def initialize(icc_stream_ref)
        @icc_stream_ref = icc_stream_ref
      end

      class << self
        def pdf_name; :ICCBased; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([:ICCBased, @icc_stream_ref])
      end
      register_as
    end

    # Indexed color space — maps small integer codes to colors in a base space.
    class Indexed < ColorSpace
      attr_reader :base, :hival, :lookup

      def initialize(base:, hival:, lookup:)
        @base = base
        @hival = hival
        @lookup = lookup
      end

      class << self
        def pdf_name; :Indexed; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([:Indexed, @base, @hival, @lookup])
      end
      register_as
    end

    # Separation color space — a single named ink (e.g. "PANTONE 185 C").
    class Separation < ColorSpace
      attr_reader :name, :alternate, :tint_transform

      def initialize(name:, alternate:, tint_transform:)
        @name = name
        @alternate = alternate
        @tint_transform = tint_transform
      end

      class << self
        def pdf_name; :Separation; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([:Separation, @name, @alternate, @tint_transform])
      end
      register_as
    end

    # DeviceN color space — multiple named inks.
    class DeviceN < ColorSpace
      attr_reader :names, :alternate, :tint_transform

      def initialize(names:, alternate:, tint_transform:)
        @names = names
        @alternate = alternate
        @tint_transform = tint_transform
      end

      class << self
        def pdf_name; :DeviceN; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([
                                     :DeviceN,
                                     Pdfrb::Model::PdfArray.new(@names),
                                     @alternate,
                                     @tint_transform,
                                   ])
      end
      register_as
    end

    # Pattern color space — for tiling and shading patterns.
    class Pattern < ColorSpace
      attr_reader :base

      def initialize(base: nil)
        @base = base
      end

      class << self
        def pdf_name; :Pattern; end
      end

      def to_pdf
        @base ? Pdfrb::Model::PdfArray.new([:Pattern, @base]) : :Pattern
      end
      register_as
    end
  end
end

# rubocop:enable Lint/MissingSuper
