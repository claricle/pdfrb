# frozen_string_literal: true

module Pdfrb
  module Source
    # Classical xref section parser (s7.5.4). Reads the table starting
    # at the given byte offset and returns an +XrefSection+.
    #
    # Format:
    #   xref
    #   <start_oid> <count>
    #   <10-digit offset> <5-digit gen> <n|f>
    #   ...
    #   trailer
    module XrefTableReader
      ENTRY_RE = /\A(\d{1,10})\s+(\d{1,5})\s+([nf])\z/.freeze
      SUBHEADER_RE = /\A(\d+)\s+(\d+)\z/.freeze
      private_constant :ENTRY_RE
      private_constant :SUBHEADER_RE

      module_function

      def read(io, offset)
        io.seek(offset, IO::SEEK_SET)
        line = io.gets&.strip
        raise Pdfrb::ParseError, "missing xref keyword at #{offset}" unless line == "xref"

        section = XrefSection.new
        next_oid = 0
        while (raw = io.gets)
          line = raw.strip
          next if line.empty?
          break if line == "trailer"

          if (m = SUBHEADER_RE.match(line))
            next_oid = m[1].to_i
            count = m[2].to_i
            count.times do |i|
              row = io.gets&.strip
              break unless row

              add_entry(section, next_oid + i, row)
            end
            next_oid += 0 # subsection header advances oid implicitly above
          elsif (m = ENTRY_RE.match(line))
            # Lone entry without a subheader (some PDFs do this).
            add_entry(section, next_oid, line)
            next_oid += 1
          else
            # Unknown line — stop or skip. Be tolerant and stop.
            break
          end
        end
        section
      end

      def add_entry(section, oid, row)
        m = ENTRY_RE.match(row)
        return unless m

        offset_val = m[1].to_i
        gen = m[2].to_i
        flag = m[3]
        if flag == "n"
          section.add_in_use(oid, gen, offset_val)
        else
          section.add_free(oid, gen, offset_val)
        end
      end
      private_class_method :add_entry
    end
  end
end
