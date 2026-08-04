# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class MarkedContentReference < Cos::Dictionary
        register_type :MCR

        def page
          self[:Pg]
        end

        def content_item
          self[:MCID]
        end
      end
    end
  end
end
