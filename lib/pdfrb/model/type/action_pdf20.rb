# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoToDp action (s12.6.4.2, PDF 2.0). Destination pointer variant
      # of GoTo that supports /DP (destination page) over a /D array.
      class ActionGoToDp < Action
        register_subtype :GoToDp

        def destination_page; self[:DP]; end
        def destination; self[:D]; end
      end

      # RichMediaExecute action (s12.6.4.12, PDF 2.0). Execute a
      # command on a RichMedia annotation.
      class ActionRichMediaExecute < Action
        register_subtype :RichMediaExecute

        def target; self[:TA]; end
        def instance; self[:Instance]; end
        def arguments; self[:Args]; end
      end

      # NOP action (PDF 1.2 deprecated). No-op placeholder.
      class ActionNOP < Action
        register_subtype :NOP
      end
    end
  end
end
