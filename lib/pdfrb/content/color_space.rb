# frozen_string_literal: true

module Pdfrb
  module Content
    module ColorSpace
      REGISTRY = {} # rubocop:disable Style/MutableConstant

      class << self
        def register(name, klass)
          REGISTRY[name.to_sym] = klass
        end

        def resolve(name, _document = nil)
          REGISTRY[name.to_sym]
        end

        def families
          REGISTRY.keys
        end
      end

      class DeviceGray
        def self.family; :DeviceGray; end
        def self.components; 1; end
        def self.default; [0.0]; end
      end
      register :DeviceGray, DeviceGray

      class DeviceRGB
        def self.family; :DeviceRGB; end
        def self.components; 3; end
        def self.default; [0.0, 0.0, 0.0]; end
      end
      register :DeviceRGB, DeviceRGB

      class DeviceCMYK
        def self.family; :DeviceCMYK; end
        def self.components; 4; end
        def self.default; [0.0, 0.0, 0.0, 1.0]; end
      end
      register :DeviceCMYK, DeviceCMYK

      class CalGray
        attr_reader :white_point, :gamma

        def initialize(white_point:, gamma: 1.0)
          @white_point = white_point
          @gamma = gamma
        end

        def family; :CalGray; end
        def components; 1; end
      end
      register :CalGray, CalGray

      class CalRGB
        attr_reader :white_point, :black_point, :gamma

        def initialize(white_point:, black_point: [0, 0, 0], gamma: [1, 1, 1])
          @white_point = white_point
          @black_point = black_point
          @gamma = gamma
        end

        def family; :CalRGB; end
        def components; 3; end
      end
      register :CalRGB, CalRGB

      class Lab
        attr_reader :white_point, :black_point, :range

        def initialize(white_point:, black_point: [0, 0, 0], range: [-100, 100, -100, 100])
          @white_point = white_point
          @black_point = black_point
          @range = range
        end

        def family; :Lab; end
        def components; 3; end
      end
      register :Lab, Lab

      class ICCBased
        attr_reader :stream_ref, :alternate, :range, :n

        def initialize(stream_ref:, n:, alternate: nil, range: nil)
          @stream_ref = stream_ref
          @n = n
          @alternate = alternate
          @range = range
        end

        def family; :ICCBased; end
        def components; @n; end
      end
      register :ICCBased, ICCBased

      class Indexed
        attr_reader :base, :hival, :lookup

        def initialize(base:, hival:, lookup:)
          @base = base
          @hival = hival
          @lookup = lookup
        end

        def family; :Indexed; end
        def components; 1; end
      end
      register :Indexed, Indexed

      class Separation
        attr_reader :name, :alternate_space, :tint_transform

        def initialize(name:, alternate_space:, tint_transform:)
          @name = name
          @alternate_space = alternate_space
          @tint_transform = tint_transform
        end

        def family; :Separation; end
        def components; 1; end
      end
      register :Separation, Separation

      class DeviceN
        attr_reader :names, :alternate_space, :tint_transform

        def initialize(names:, alternate_space:, tint_transform:)
          @names = names
          @alternate_space = alternate_space
          @tint_transform = tint_transform
        end

        def family; :DeviceN; end

        def components
          (@names || []).length
        end
      end
      register :DeviceN, DeviceN

      class Pattern
        attr_reader :base_space

        def initialize(base_space: nil)
          @base_space = base_space
        end

        def family; :Pattern; end
        def components; 0; end
      end
      register :Pattern, Pattern
    end
  end
end
