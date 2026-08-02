# frozen_string_literal: true

module Pdfrb
  module Source
    # Locates `startxref` near EOF and returns its offset. Per s7.5.5,
    # the last `startxref` keyword in the file is authoritative.
    module TrailerReader
      SCAN_BYTES = 1024

      module_function

      # Returns the byte offset of the xref section (the value of the
      # last `startxref` keyword in the file), or nil if not found.
      def startxref_offset(io)
        size = io.size
        back = [SCAN_BYTES, size].min
        io.seek(size - back, IO::SEEK_SET)
        tail = io.read(back)
        return nil unless tail

        idx = tail.rindex("startxref")
        return nil unless idx

        rest = tail[(idx + "startxref".length)..]
        m = rest.match(/(\d+)/)
        return nil unless m

        m[1].to_i
      end
    end
  end
end
