# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class MarkInformation < Cos::Dictionary
        register_type :MarkInfo

        def marked?
          self[:Marked] == true
        end

        def user_properties?
          self[:UserProperties] == true
        end

        def suspects?
          self[:Suspects] == true
        end
      end
    end
  end
end
