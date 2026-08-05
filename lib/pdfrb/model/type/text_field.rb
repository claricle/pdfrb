# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class TextField < Field
        def max_len; self[:MaxLen]; end
        def value; self[:V]; end
        def rich_text_value; self[:RV]; end

        def multiline?; flags & 0x1000 != 0; end
        def password?; flags & 0x2000 != 0; end
        def file_select?; flags & 0x100000 != 0; end
        def do_not_spell_check?; flags & 0x400000 != 0; end
        def do_not_scroll?; flags & 0x800000 != 0; end
        def comb?; flags & 0x1000000 != 0; end
        def rich_text?; flags & 0x2000000 != 0; end
      end
    end
  end
end
