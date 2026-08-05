# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DeviceN Process (s8.6.6.4). Process colorant list.
      class DeviceNProcess < Pdfrb::Model::Cos::Dictionary
        def color_space; self[:ColorSpace]; end
        def components; self[:Components]; end
      end
    end
  end
end
