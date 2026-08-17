# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Movie action (s12.6.4.8). Deprecated in PDF 2.0 but still
      # appears in legacy PDFs. Plays/stops a Movie annotation.
      class ActionMovie < Action
        arlington_object "ActionMovie"
        register_subtype :Movie

        def annotation; self[:Annotation]; end
        def title; self[:T]; end
        def operation; self[:Operation]&.to_sym || :Play; end

        def play?; operation == :Play; end
        def stop?; operation == :Stop; end
        def pause?; operation == :Pause; end
        def resume?; operation == :Resume; end
      end
    end
  end
end
