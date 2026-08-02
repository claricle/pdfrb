# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Output intent (s14.11.5) — ICC profile + condition metadata.
      class OutputIntent < Pdfrb::Model::Cos::Dictionary
        arlington_object "OutputIntents"
      end
    end
  end
end
