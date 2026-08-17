# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoTo3DView action (s12.6.4.12, PDF 1.6+). Navigate within a 3D stream.
      class ActionGoTo3DView < Action
        arlington_object "ActionGoTo3DView"
        register_subtype :GoTo3DView

        def target_view; self[:TA]; end
      end
    end
  end
end
