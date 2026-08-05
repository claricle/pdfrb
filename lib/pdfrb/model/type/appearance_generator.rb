# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class AppearanceGenerator
        def self.for(annotation, document:)
          case annotation[:Subtype]
          when :Widget
            WidgetAppearance.new(annotation, document)
          when :Text
            TextAppearance.new(annotation, document)
          when :Link
            LinkAppearance.new(annotation, document)
          else
            GenericAppearance.new(annotation, document)
          end
        end
      end
    end
  end
end
