# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Settings (s13.6.2). Top-level activation/deactivation
      # configuration for a RichMedia annotation.
      class RichMediaSettings < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def activation; self[:Activation]; end
        def deactivation; self[:Deactivation]; end

        def has_activation?
          !!activation
        end

        def resolved_activation
          ref = activation
          return nil unless ref && document

          document.object(ref)
        end

        def resolved_deactivation
          ref = deactivation
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
