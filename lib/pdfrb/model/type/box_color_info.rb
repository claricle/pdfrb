# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Box Color Info dictionary (s7.7.3.3, Table 30). Defines the
      # visual guide lines for page boxes (crop, bleed, trim, art) in
      # the viewer. Lives on Page /BoxColorInfo.
      class BoxColorInfo < Pdfrb::Model::Cos::Dictionary
        arlington_object "BoxColorInfo"
        def crop_box_style; self[:CropBox]; end
        def bleed_box_style; self[:BleedBox]; end
        def trim_box_style; self[:TrimBox]; end
        def art_box_style; self[:ArtBox]; end

        def empty?
          !crop_box_style && !bleed_box_style && !trim_box_style && !art_box_style
        end
      end
    end
  end
end
