# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Opt Content Page Element (s8.11). Marks page elements for
      # automatic optional-content group creation.
      class OptContentPageElement < Pdfrb::Model::Cos::Dictionary
        def subtype; self[:Subtype]&.to_sym; end
        def ocgs; self[:OCGs]; end

        def has_ocgs?
          !!ocgs && (!ocgs.is_a?(Array) || !ocgs.empty?)
        end
      end
    end
  end
end
