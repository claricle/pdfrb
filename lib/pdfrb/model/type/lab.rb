# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Lab color space dictionary (s8.6.3.4). CIE L*a*b*:
      # [/Lab <dict>].
      class Lab < Pdfrb::Model::Cos::Dictionary
        arlington_object "LabDict"
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def range; self[:Range]; end

        def components; 3; end

        # /Range is [a_min a_max b_min b_max]; defaults per spec are
        # [-100 100 -100 100].
        def a_range
          range ? [range[0], range[1]] : [-100, 100]
        end

        def b_range
          range ? [range[2], range[3]] : [-100, 100]
        end
      end
    end
  end
end
