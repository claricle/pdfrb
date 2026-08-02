# frozen_string_literal: true

module Pdfrb
  module Source
    # Linearization detection (s7.6.2). A linearized PDF has a
    # Linearization dict as its first indirect object, immediately
    # after the header. Detecting this lets readers stream pages in
    # order (vs. waiting for the whole file to load).
    module LinearizationDetection
      module_function

      # Returns true if the file at +io+ is linearized (per the
      # heuristic from s7.6.2: first indirect object carries a
      # /Linearized key).
      def linearized?(io)
        # Skip header.
        Pdfrb::Source::HeaderReader.read(io)
        tokenizer = Pdfrb::Source::Tokenizer.new(io)
        parser = Pdfrb::Source::Parser.new(tokenizer)
        # Parse the first indirect object we find.
        tok = tokenizer.peek
        return false unless tok&.type == :integer

        obj = parser.parse_indirect_object
        return false unless obj.value.is_a?(::Hash)

        obj.value.key?(:Linearized)
      rescue StandardError
        # Malformed input isn't linearized for our purposes.
        false
      end
    end
  end
end
