# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # NOP action (PDF 1.2 deprecated). No-op placeholder.
      class ActionNOP < Action
        register_subtype :NOP
      end
    end
  end
end
