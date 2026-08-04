# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ObjectReference < Cos::Dictionary
        register_type :ObjRef
        def page; self[:Pg]; end
        def object; self[:Obj]; end
      end
    end
  end
end
