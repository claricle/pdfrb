# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Optional Content Properties (s8.11.1). Catalog /OCProperties.
      class OptionalContentProperties < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentProperties"

        def ocgs; self[:OCGs]; end
        def default_config; self[:D]; end
        def configs; self[:Configs]; end
        def list_mode; self[:ListMode]; end

        def has_configs?
          !!configs
        end

        def base_state
          return :ON_UNLESS_OFF unless default_config
          default_config[:BaseState]&.to_sym || :ON_UNLESS_OFF
        end
      end
    end
  end
end
