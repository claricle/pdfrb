# frozen_string_literal: true

module Pdfrb
  module Source
    # Object streams (s7.5.7). Decodes the /Type /ObjStm stream and
    # yields (oid, value) pairs.
    module ObjectStreamReader
      module_function

      # Returns an Array of (oid, value) pairs in declaration order.
      def read(stream_object, document)
        decoded = stream_object.decoded_stream
        dict = stream_object
        n = dict[:N]
        first = dict[:First] || 0
        raise Pdfrb::ParseError, "ObjStm missing /N or /First" if n.nil? || first.nil?

        # Header: N pairs of "oid offset" separated by whitespace.
        header = decoded.byteslice(0, first)
        pairs = header.split(/\s+/).each_slice(2).to_a
        raise Pdfrb::ParseError, "ObjStm header mismatch" unless pairs.length == n

        body_io = StringIO.new(decoded.byteslice(first..).to_s.b)
        tokenizer = Tokenizer.new(body_io)
        parser = Parser.new(tokenizer, document: document)
        pairs.each_with_index.map do |(oid_s, _off_s), _i|
          [oid_s.to_i, parser.parse_value]
        end
      end
    end
  end
end
