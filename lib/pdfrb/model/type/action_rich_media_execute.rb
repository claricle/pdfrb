# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # RichMediaExecute action (s12.6.4.12, PDF 2.0). Execute a
      # command on a RichMedia annotation.
      class ActionRichMediaExecute < Action
        arlington_object "ActionRichMediaExecute"
        register_subtype :RichMediaExecute

        def target; self[:TA]; end
        def instance; self[:TI]; end
        def command; self[:CMD]; end
      end
    end
  end
end
