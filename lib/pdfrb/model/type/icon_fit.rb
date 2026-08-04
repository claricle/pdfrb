# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class IconFit < Cos::Dictionary
        register_type :IconFit

        def scale_type
          self[:SW]
        end

        def fit
          self[:S]
        end
      end
    end
  end
end
