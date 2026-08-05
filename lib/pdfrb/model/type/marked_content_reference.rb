# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Marked-Content Reference (s14.7.6.2). Refers to a marked-content
      # sequence on a page by MCID.
      class MarkedContentReference < Cos::Dictionary
        register_type :MCR

        def type; self[:Type]; end
        def page; self[:Pg]; end
        def content_item; self[:MCID]; end

        def resolved_page
          ref = page
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
