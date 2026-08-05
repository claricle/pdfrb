# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Choice < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end
        def top_index; self[:TI]; end
        def indices; self[:I]; end

        def combo?; flags & 0x20000 != 0; end
        def list?; !combo?; end
        def edit?; flags & 0x40000 != 0; end
        def multi_select?; flags & 0x200000 != 0; end
        def sort?; flags & 0x80000 != 0; end
        def commit_on_change?; flags & 0x4000000 != 0; end
      end
    end
  end
end
