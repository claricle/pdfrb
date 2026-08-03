# frozen_string_literal: true

module Pdfrb
  module Content
    # Shading patterns (ISO 32000-2 §8.7.4). Shadings define smooth
    # color transitions: axial (linear) gradients, radial gradients,
    # and free-form Gouraud-triangle meshes.
    #
    # Each shading is a dictionary with /ShadingType and type-specific
    # parameters. Registered in page Resources under /Shading.
    module Shading
      autoload :Base, "pdfrb/content/shading/base"
      autoload :Axial, "pdfrb/content/shading/base"
      autoload :Radial, "pdfrb/content/shading/base"
    end
  end
end
