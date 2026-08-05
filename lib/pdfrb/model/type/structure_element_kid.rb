# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure Element Kid Reference. When a struct element's kid
      # is a content-stream marker (MCID), the kid is represented as
      # an integer; when it's a sub-element, it's a dict reference.
      class StructureElementKid < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def page; self[:Pg]; end
        def mcid; self[:MCID]; end
        def object; self[:Obj]; end
        def structure_type; self[:S]; end

        def content_item?
          !mcid.nil?
        end

        def object_reference?
          !!object
        end

        def resolved_page
          ref = page
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
