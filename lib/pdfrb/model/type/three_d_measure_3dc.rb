# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Comment (3DC) measure (s13.6.4). A 3D measurement note.
      class ThreeDMeasure3DC < ThreeDMeasure
        arlington_object "3DMeasure3DC"
        def text; self[:TRL]; end
        def anchor; self[:A1]; end
        def name; self[:N1]; end
        def text_position; self[:TP]; end
        def text_box; self[:TB]; end
        def text_size; self[:TS] || 12; end
        def color; self[:C]; end
        def unit_text; self[:UT]; end

        def default_color?
          color == [1, 1, 1]
        end
      end
    end
  end
end
