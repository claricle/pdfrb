# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Activation (s13.6.2). Controls when a 3D stream becomes
      # active and how it's deactivated.
      class ThreeDActivation < Pdfrb::Model::Cos::Dictionary
        def activation_mode; self[:A]&.to_sym; end
        def activation_instance; self[:AIS]&.to_sym; end
        def deactivation_mode; self[:D]&.to_sym; end
        def deactivation_instance; self[:DIS]&.to_sym; end
        def toolbar?; truthy?(self[:TB]); end
        def new_page?; truthy?(self[:NP]); end
        def style; self[:Style]&.to_sym; end
        def transparent?; truthy?(self[:Transparent]); end
        def window; self[:Window]; end

        def activation_on_click?; activation_mode == :PO; end
        def activation_on_page_open?; activation_mode == :PV; end
        def activation_on_page_visible?; activation_mode == :XA; end

        def deactivation_on_page_close?; deactivation_mode == :PC; end
        def deactivation_on_page_hidden?; deactivation_mode == :PI; end
        def deactivation_on_external_deactivation?; deactivation_mode == :XD; end

        def embedded_style?; style == :Embedded; end
        def windowed_style?; style == :Windowed; end
      end
    end
  end
end
