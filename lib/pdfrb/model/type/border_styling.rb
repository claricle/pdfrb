# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # BorderStyling (s12.5.4.1, PDF 2.0). Replaces the deprecated
      # /Border array on annotations. Specifies width, dash, style.
      class BorderStyling < Cos::Dictionary
        register_type :BorderStyling

        def type; self[:Type]; end
        def style; self[:S]&.to_sym; end
        def width; self[:W] || 1.0; end
        def dash; self[:D]; end

        def solid?; style.nil? || style == :S; end
        def dashed?; style == :D; end
        def beveled?; style == :B; end
        def inset?; style == :I; end
        def underline?; style == :U; end

        def dash_array
          return nil unless dash

          arr = dash.is_a?(Pdfrb::Model::PdfArray) ? dash.to_a : dash
          arr.is_a?(Array) && arr.size >= 1 ? arr[0] : nil
        end

        def dash_phase
          return nil unless dash

          arr = dash.is_a?(Pdfrb::Model::PdfArray) ? dash.to_a : dash
          arr.is_a?(Array) && arr.size >= 2 ? arr[1] : 0
        end
      end
    end
  end
end
