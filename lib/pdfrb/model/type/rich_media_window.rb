# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Window (s13.6.1). Window dimensions and position
      # for windowed rich media.
      class RichMediaWindow < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaWindow"
        def type; self[:Type]; end
        def width; self[:Width]; end
        def height; self[:Height]; end
        def position; self[:Position]; end

        def has_dimensions?
          !!width && !!height
        end
      end
    end
  end
end
