# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Box Style dictionary (s7.7.3.3, Table 396). Describes one box
      # guide: color, dash pattern, visibility.
      class BoxStyle < Pdfrb::Model::Cos::Dictionary
        def color; self[:C]; end
        def dash_pattern; self[:W]; end
        def dash_style; self[:S]&.to_sym; end
        def dash_count; self[:D]; end

        def solid?; dash_style.nil? || dash_style == :S; end
        def dashed?; dash_style == :D; end
      end
    end
  end
end
