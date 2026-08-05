# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Button < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end

        def push_button?; flags & 0x10000 != 0; end
        def radio?; flags & 0x8000 != 0; end
        def no_toggle_to_off?; flags & 0x4000 != 0; end
        def radios_in_unison?; flags & 0x2000000 != 0; end
      end
    end
  end
end
