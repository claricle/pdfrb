# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Choice < Field
        arlington_object "FieldChoice"
        def value; self[:V]; end
        def opt; self[:Opt]; end
        def top_index; self[:TI]; end
        def indices; self[:I]; end

        def combo?; flags.anybits?(0x20000); end
        def list?; !combo?; end
        def edit?; flags.anybits?(0x40000); end
        def multi_select?; flags.anybits?(0x200000); end
        def sort?; flags.anybits?(0x80000); end
        def commit_on_change?; flags.anybits?(0x4000000); end
      end
    end
  end
end
