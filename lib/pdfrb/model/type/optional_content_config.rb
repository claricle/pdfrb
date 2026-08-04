# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class OptionalContentConfiguration < Cos::Dictionary
        register_type :OCConfig

        def name; self[:Name]; end
        def creator; self[:Creator]; end
        def base_state; self[:BaseState] || :ON; end
        def on; self[:ON]; end
        def off; self[:OFF]; end
      end
    end
  end
end
