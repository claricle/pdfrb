# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Deactivation (s13.6.1). Deactivation behaviour.
      class RichMediaDeactivation < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def condition; self[:Condition]&.to_sym; end

        def deactivation_on_click?; condition == :PC; end
        def deactivation_on_page_close?; condition == :PI; end
        def deactivation_on_page_hidden?; condition == :XD; end
      end
    end
  end
end
