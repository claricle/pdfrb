# frozen_string_literal: true

module Pdfrb
  module Source
    # Last-resort recovery: scan the entire file for `\d+ \d+ obj`
    # patterns and synthesise an XrefSection from the offsets found.
    # Triggered when the xref table is missing or points to a wrong
    # offset.
    module Recovery
      OBJ_PATTERN = /(\d+)\s+(\d+)\s+obj\b/.freeze
      private_constant :OBJ_PATTERN

      module_function

      def rebuild_xref(io, recover: true)
        return nil unless recover

        io.seek(0, IO::SEEK_SET)
        section = XrefSection.new
        data = io.read
        data.force_encoding(Encoding::BINARY)
        offset = 0
        while (m = data.match(OBJ_PATTERN, offset))
          oid = m[1].to_i
          gen = m[2].to_i
          entry_offset = m.begin(0)
          # Take the last-seen gen per oid (PDF spec: highest gen wins).
          section.add_in_use(oid, gen, entry_offset)
          offset = m.end(0)
        end
        section
      end
    end
  end
end
