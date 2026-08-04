# frozen_string_literal: true

module Pdfrb
  module Content
    # Color space registry and conversion. Follows OCP: adding a new
    # color space = registering a class, no switch edits.
    module ColorSpace
      REGISTRY = {}

      class << self
        def register(name, klass)
          REGISTRY[name.to_sym] = klass
        end

        def resolve(name, document = nil)
          REGISTRY[name.to_sym]
        end

        def families
          REGISTRY.keys
        end
      end

      # DeviceGray: single-component gray (0=black, 1=white)
      class DeviceGray
        def self.family; :DeviceGray; end
        def self.components; 1; end
        def self.default; [0.0]; end
      end
      register :DeviceGray, DeviceGray

      # DeviceRGB: three-component additive color
      class DeviceRGB
        def self.family; :DeviceRGB; end
        def self.components; 3; end
        def self.default; [0.0, 0.0, 0.0]; end
      end
      register :DeviceRGB, DeviceRGB

      # DeviceCMYK: four-component subtractive color
      class DeviceCMYK
        def self.family; :DeviceCMYK; end
        def self.components; 4; end
        def self.default; [0.0, 0.0, 0.0, 1.0]; end
      end
      register :DeviceCMYK, DeviceCMYK

      # CalGray: calibrated gray with white point and gamma
      class CalGray
        attr_reader :white_point, :gamma

        def initialize(white_point:, gamma: 1.0)
          @white_point = white_point
          @gamma = gamma
        end

        def self.family; :CalGray; end
        def self.components; 1; end
      end
      register :CalGray, CalGray

      # CalRGB: calibrated RGB with white/black point and gamma
      class CalRGB
        attr_reader :white_point, :black_point, :gamma

        def initialize(white_point:, black_point: [0, 0, 0], gamma: [1, 1, 1])
          @white_point = white_point
          @black_point = black_point
          @gamma = gamma
        end

        def self.family; :CalRGB; end
        def self.components; 3; end
      end
      register :CalRGB, CalRGB

      # Lab: CIE L*a*b* color space
      class Lab
        attr_reader :white_point, :black_point, :range

        def initialize(white_point:, black_point: [0, 0, 0], range: [-100, 100, -100, 100])
          @white_point = white_point
          @black_point = black_point
          @range = range
        end

        def self.family; :Lab; end
        def self.components; 3; end
      end
      register :Lab, Lab

      # ICCBased: ICC profile-based color space
      class ICCBased
        attr_reader :stream_ref, :alternate, :range, :n

        def initialize(stream_ref:, n:, alternate: nil, range: nil)
          @stream_ref = stream_ref
          @n = n
          @alternate = alternate
          @range = range
        end

        def self.family; :ICCBased; end

        def components; @n; end
      end
      register :ICCBased, ICCBased

      # Indexed: lookup table maps byte index → color components
      class Indexed
        attr_reader :base, :hival, :lookup

        def initialize(base:, hival:, lookup:)
          @base = base
          @hival = hival
          @lookup = lookup
        end

        def self.family; :Indexed; end
        def self.components; 1; end
      end
      register :Indexed, Indexed

      # Separation: single named ink (e.g., PANTONE 185)
      class Separation
        attr_reader :name, :alternate_space, :tint_transform

        def initialize(name:, alternate_space:, tint_transform:)
          @name = name
          @alternate_space = alternate_space
          @tint_transform = tint_transform
        end

        def self.family; :Separation; end
        def self.components; 1; end
      end
      register :Separation, Separation

      # DeviceN: multiple named inks
      class DeviceN
        attr_reader :names, :alternate_space, :tint_transform

        def initialize(names:, alternate_space:, tint_transform:)
          @names = names
          @alternate_space = alternate_space
          @tint_transform = tint_transform
        end

        def self.family; :DeviceN; end
        def self.components; 0; end

        def components
          @namesdef self.components; @names&.length || 0; end.length || 0
        end
      end
      register :DeviceN, DeviceN

      # Pattern: pattern color space
      class Pattern
        attr_reader :base_space

        def initialize(base_space: nil)
          @base_space = base_space
        end

        def self.family; :Pattern; end
        def self.components; 0; end
      end
      register :Pattern, Pattern
    end
  end
end
