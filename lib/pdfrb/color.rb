# frozen_string_literal: true

module Pdfrb
  # Color spaces and color management. Provides domain types for
  # device color spaces (DeviceGray/RGB/CMYK), CIE-based spaces
  # (CalGray, CalRGB, Lab, ICCBased), and special spaces (Indexed,
  # Separation, DeviceN, Pattern).
  module Color
    autoload :ICCProfile, "pdfrb/color/icc_profile"
    autoload :ColorSpace, "pdfrb/color/color_space"
    autoload :DefaultProfile, "pdfrb/color/default_profile"
    autoload :ICCValidator, "pdfrb/color/icc_validator"
  end
end
