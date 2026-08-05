# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Software Identifier (s13.3.5.5). Identifies a player for
      # media rendering.
      class SoftwareIdentifier < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def u; self[:U]; end
        def l; self[:L]; end

        def has_version?
          !!u && !!l
        end
      end
    end
  end
end
