# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Object reference dict (s14.7.6). Used in structure trees to
      # refer to a content item without including it directly.
      class ObjectReference < Cos::Dictionary
        register_type :ObjRef

        def type; self[:Type]; end
        def page; self[:Pg]; end
        def object; self[:Obj]; end

        def resolved_page
          ref = page
          return nil unless ref && document

          document.object(ref)
        end

        def resolved_object
          ref = object
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
