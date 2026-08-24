# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # OPI version 1.3 dictionary (s14.11.6, deprecated 2.0):
      # low-resolution proxy information for OPI workflows.
      class OPIVersion13Dict < Pdfrb::Model::Cos::Dictionary
        arlington_object "OPIVersion13Dict"

        def version; self[:Version]; end
        def file_spec; self[:F]; end
        def id; self[:ID]; end
        def comments; self[:Comments]; end
        def size; self[:Size]; end
        def crop_rect; self[:CropRect]; end
        def crop_fixed; self[:CropFixed]; end
        def position; self[:Position]; end
        def resolution; self[:Resolution]; end
        def color_type; self[:ColorType]; end
        def color; self[:Color]; end
        def tint; self[:Tint]; end
        def overprint; self[:Overprint]; end
        def image_type; self[:ImageType]; end
        def gray_map; self[:GrayMap]; end
        def transparency; self[:Transparency]; end
        def tags; self[:Tags]; end
      end

      # OPI version 2.0 dictionary (s14.11.6, deprecated 2.0).
      class OPIVersion20Dict < Pdfrb::Model::Cos::Dictionary
        arlington_object "OPIVersion20Dict"

        def version; self[:Version]; end
        def file_spec; self[:F]; end
        def id; self[:ID]; end
        def comments; self[:Comments]; end
        def size; self[:Size]; end
        def crop_rect; self[:CropRect]; end
        def position; self[:Position]; end
        def resolution; self[:Resolution]; end
        def color_type; self[:ColorType]; end
        def tint; self[:Tint]; end
        def overprint; self[:Overprint]; end
        def image_type; self[:ImageType]; end
        def transparency; self[:Transparency]; end
        def tags; self[:Tags]; end
      end
    end
  end
end
