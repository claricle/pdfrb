# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # UserProperty (ISO 32000-2 §14.7.5). A single property in the
      # /P array of a user property list attached to structure
      # elements for custom metadata.
      class UserProperty < Pdfrb::Model::Cos::Dictionary
        arlington_object "UserProperty"

        # /N — required, the property name.
        def name
          value[:N]
        end

        # /V — required, the property value (any COS type).
        def property_value
          value[:V]
        end

        # /F — optional, a text string with the intended format of
        # the value.
        def format
          value[:F]
        end

        # /H — optional, whether the property is hidden from the
        # user (default false).
        def hidden?
          value[:H] == true
        end
      end
    end
  end
end
