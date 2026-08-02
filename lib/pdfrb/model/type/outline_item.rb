# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Single bookmark entry. Lives in its own file so the autoload
      # path matches the TSV-derived class name.
      class OutlineItem < Pdfrb::Model::Cos::Dictionary
        arlington_object "OutlineItem"
      end
    end
  end
end
