# frozen_string_literal: true

require "stringio"

module Pdfrb
  module Source
    # Convenience entry points for tests + one-shot parsing.
    module_function

    def parse_string(source, document: nil)
      io = source.is_a?(::String) ? StringIO.new(source.b) : source
      Parser.new(Tokenizer.new(io), document: document).parse_value
    end

    def tokenize_string(source)
      io = source.is_a?(::String) ? StringIO.new(source.b) : source
      tokens = []
      tokenizer = Tokenizer.new(io)
      while (t = tokenizer.next_token)
        tokens << t
      end
      tokens
    end
  end
end
