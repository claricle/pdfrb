# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Activation (s13.6.1). Activation behaviour settings.
      class RichMediaActivation < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def condition; self[:Condition]&.to_sym; end
        def configuration; self[:Configuration]; end
        def presentation; self[:Presentation]; end
        def scripts; self[:Scripts]; end

        def activation_on_click?; condition == :PO; end
        def activation_on_page_open?; condition == :PV; end
        def activation_on_page_visible?; condition == :XA; end

        def has_configuration?
          !!configuration
        end
      end
    end
  end
end
