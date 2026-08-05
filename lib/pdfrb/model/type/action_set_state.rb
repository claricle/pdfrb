# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Set-state action (deprecated in PDF 1.2, replaced by SetOCGState).
      class ActionSetState < Action
        register_subtype :SetState

        def state; self[:State]; end
      end
    end
  end
end
