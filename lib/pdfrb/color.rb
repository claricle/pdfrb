# frozen_string_literal: true

module Pdfrb
  # Color spaces and color management. Provides domain types for
  # device color spaces (DeviceGray/RGB/CMYK), CIE-based spaces
  # (CalGray, CalRGB, Lab, ICCBased), and special spaces (Indexed,
  # Separation, DeviceN, Pattern).
  #
  # The Color module owns color space *definitions* — the data model
  # that goes into a page's /Resources /ColorSpace dictionary. Content
  # operators (cs, CS, scn, SCN) reference these by name; this module
  # is responsible for building and registering the named entries.
  module Color
    autoload :ICCProfile, "pdfrb/color/icc_profile"
    autoload :ColorSpace, "pdfrb/color/color_space"
  end
end

# Eager-load color space subclasses so register_as calls populate
# ColorSpace::REGISTRY before any lookup.
require "pdfrb/color/color_space"
