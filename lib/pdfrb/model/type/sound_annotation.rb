# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Sound annotation (s12.5.6.18). Sound clip embedded in the page.
      class SoundAnnotation < MarkupAnnotation
        def sound; self[:Sound]; end
        def name; self[:Name]; end

        def icon_name
          (name || :Speaker).to_sym
        end

        def has_sound?
          !!sound
        end
      end
    end
  end
end
