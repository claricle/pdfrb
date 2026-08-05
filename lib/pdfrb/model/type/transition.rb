# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Page Transition dict (s12.4.3). Animation for moving between
      # pages in FullScreen mode. Lives on Page /Trans or on an
      # ActionTrans.
      class Transition < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def style; self[:S]&.to_sym; end
        def duration; self[:D]; end
        def dimension; self[:Dm]&.to_sym; end
        def motion_direction; self[:M]&.to_sym; end
        def direction; self[:Di] || 0; end
        def scale; self[:SS] || 1.0; end
        def bidirectional?; truthy?(self[:B]); end

        def split?; style == :Split; end
        def blinds?; style == :Blinds; end
        def box?; style == :Box; end
        def wipe?; style == :Wipe; end
        def dissolve?; style == :Dissolve; end
        def glitter?; style == :Glitter; end
        def fly?; style == :Fly; end
        def push?; style == :Push; end
        def cover?; style == :Cover; end
        def uncover?; style == :Uncover; end
        def fade?; style == :Fade; end

        def horizontal?; dimension == :H; end
        def vertical?; dimension == :V; end

        def inward?; motion_direction == :I; end
        def outward?; motion_direction == :O; end
      end

      # Printer Mark sub-dictionary (s12.5.6.18). Per-printer-mark
      # sub-parameters.
      class PrinterMarkSubDict < Pdfrb::Model::Cos::Dictionary
        def printer; self[:PRINTER]; end
        def credentials; self[:CREDS]; end
      end

      # ExData 3D Markup (s13.6.1). 3D scene metadata for Projection
      # annotations / 3D models.
      class ExData3DMarkup < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def v3d; self[:V3D]; end

        def has_3d?
          !!v3d
        end
      end

      # ExData Markup Geo (s12.5.6.21). Geo-spatial markup attached to
      # a Projection annotation.
      class ExDataMarkupGeo < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def coordinate_path; self[:CoordinatePath]; end

        def has_coordinate_path?
          !!coordinate_path
        end
      end
    end
  end
end
