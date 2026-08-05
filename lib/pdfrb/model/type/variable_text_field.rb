# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Variable Text Field (s12.7.4.3). Base for text fields with
      # dynamic appearance generation. Adds /DA, /Q, /RV.
      class VariableTextField < Field
        def default_appearance; self[:DA]; end
        def da; self[:DA]; end
        def q; self[:Q]; end
        def rv; self[:RV]; end

        def text_alignment
          case q
          when 1 then :center
          when 2 then :right
          when 3 then :justify
          else :left
          end
        end

        def has_rich_text?
          !!rv
        end

        def default_appearance_font
          return nil unless default_appearance

          match = default_appearance.to_s.match(/\/(\w+)\s+([\d.]+)\s+Tf/)
          return nil unless match

          [match[1].to_sym, match[2].to_f]
        end

        def default_appearance_color
          return nil unless default_appearance

          match = default_appearance.to_s.match(/([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+rg/)
          return nil unless match

          [match[1].to_f, match[2].to_f, match[3].to_f]
        end
      end
    end
  end
end
