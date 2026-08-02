# frozen_string_literal: true

module Pdfrb
  module Source
    # One lexed token. +type+ is a Symbol; +value+ is the literal
    # bytes/string/number as parsed from source; +position+ is the
    # byte offset in the IO where the token started (used for
    # diagnostics and xref).
    Token = Struct.new(:type, :value, :position, keyword_init: true) do
      def inspect
        "#<Pdfrb::Source::Token #{type} value=#{value.inspect} pos=#{position}>"
      end
    end
  end
end
