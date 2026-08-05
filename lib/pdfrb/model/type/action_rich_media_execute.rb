# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # RichMediaExecute action (s12.6.4.12, PDF 2.0). Execute a
      # command on a RichMedia annotation.
      class ActionRichMediaExecute < Action
        register_subtype :RichMediaExecute

        def target; self[:TA]; end
        def instance; self[:Instance]; end
        def arguments; self[:Args]; end
      end
    end
  end
end
