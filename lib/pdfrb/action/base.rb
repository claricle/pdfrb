# frozen_string_literal: true

module Pdfrb
  module Action
    # Base action builder. Subclasses define +action_type+ (the /S value)
    # and +to_pdf+ (type-specific serialization).
    class Base
      class << self
        # @return [Symbol] the /S value (e.g. :GoTo, :URI).
        def action_type
          raise NotImplementedError
        end

        def register_as(name = action_type)
          Action.register(name, self)
          self
        end
      end
    end
  end
end
