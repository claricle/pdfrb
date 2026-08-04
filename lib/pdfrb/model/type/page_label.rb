# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class PageLabel < Cos::Dictionary
        register_type :PageLabel

        def style; self[:S]; end
        def prefix; self[:P]; end
        def start; self[:St] || 1; end
      end
    end
  end
end
