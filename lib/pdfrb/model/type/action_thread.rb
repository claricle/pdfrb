# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Thread action (s12.6.4.6). Navigate within an article thread.
      class ActionThread < Action
        register_subtype :Thread

        def thread; self[:F]; end
        def destination_bead; self[:D]; end

        def first_bead?
          destination_bead.zero? || destination_bead.nil?
        end

        def last_bead?
          destination_bead == -1
        end
      end
    end
  end
end
