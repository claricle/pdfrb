# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class TextField < Field
        arlington_object "FieldTx"
        def max_len; self[:MaxLen]; end
        def value; self[:V]; end
        def rich_text_value; self[:RV]; end

        def multiline?; flags.anybits?(0x1000); end
        def password?; flags.anybits?(0x2000); end
        def file_select?; flags.anybits?(0x100000); end
        def do_not_spell_check?; flags.anybits?(0x400000); end
        def do_not_scroll?; flags.anybits?(0x800000); end
        def comb?; flags.anybits?(0x1000000); end
        def rich_text?; flags.anybits?(0x2000000); end
      end
    end
  end
end
