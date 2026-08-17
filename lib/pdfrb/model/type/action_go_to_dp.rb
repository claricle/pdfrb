# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoToDp action (s12.6.4.2, PDF 2.0). Destination pointer variant
      # of GoTo that supports /DP (destination page) over a /D array.
      class ActionGoToDp < Action
        arlington_object "ActionGoToDp"
        register_subtype :GoToDp

        def destination_page; self[:DP]; end
        def destination; self[:D]; end
      end
    end
  end
end
