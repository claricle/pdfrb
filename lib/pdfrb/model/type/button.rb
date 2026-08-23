# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Button < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end

        def push_button?; flags & 0x10000 != 0; end
        def radio?; flags & 0x8000 != 0; end
        def checkbox?; !push_button? && !radio?; end
        def no_toggle_to_off?; flags & 0x4000 != 0; end
        def radios_in_unison?; flags & 0x2000000 != 0; end
      end

      # Checkbox button field (s12.7.4.2.2, /Ft /Btn without push or
      # radio flags).
      class CheckboxButton < Button
        arlington_object "FieldBtnCheckbox"
      end

      # Pushbutton field (s12.7.4.2.4).
      class PushButton < Button
        arlington_object "FieldBtnPush"
      end

      # Radio button field (s12.7.4.2.3).
      class RadioButton < Button
        arlington_object "FieldBtnRadio"
      end
    end
  end
end
