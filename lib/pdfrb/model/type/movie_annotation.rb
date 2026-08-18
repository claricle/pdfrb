# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Movie annotation (s12.5.6.14). /Subtype /Movie. Plays a Movie
      # when activated.
      class MovieAnnotation < Annotation
        arlington_object "AnnotMovie"

        def movie; self[:Movie]; end
        def action; self[:A]; end
        def title; self[:T]; end

        def has_movie?
          !movie.nil?
        end

        def uses_action?
          !action.nil?
        end
      end
    end
  end
end
