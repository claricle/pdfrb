# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Outline (bookmark) root (s12.3.3). Linked from Catalog /Outlines.
      class Outline < Pdfrb::Model::Cos::Dictionary
        arlington_object "Outline"
        register_type :Outlines
      end

      # One bookmark entry (s12.3.3). Forms a doubly-linked list with
      # /Next, /Prev, /First, /Last, /Parent; carries /Title, /A or
      # /Dest for the navigation target.
      class OutlineItem < Pdfrb::Model::Cos::Dictionary
        arlington_object "OutlineItem"
      end
    end
  end
end
