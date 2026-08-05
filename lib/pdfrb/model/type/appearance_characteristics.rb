# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Appearance Characteristics dictionary (s12.5.5). Defines the
      # visual characteristics of a widget annotation: background/caption
      # colors, normal/rollover/down captions, etc. Often stored under
      # the widget's /MK key.
      class AppearanceCharacteristics < Pdfrb::Model::Cos::Dictionary
        def background_color; self[:BG]; end
        def caption; self[:CA]; end
        def rollover_caption; self[:RC]; end
        def down_caption; self[:AC]; end
        def rotation; self[:R] || 0; end
        def border_color; self[:BC]; end
        def normal_icon; self[:IF]; end
        def alternate_icon; self[:IX]; end
        def icon_fit; self[:IF]; end
        def tp; self[:TP]; end

        def text_position
          tp || 0
        end

        def has_background?
          !!background_color
        end

        def has_caption?
          !!caption
        end
      end
    end
  end
end
