# frozen_string_literal: true

module Pdfrb
  module Filter
    # RunLengthDecode (s7.4.5). Length byte 0..127 = N+1 literal bytes;
    # 129..255 = repeat next byte (257 - N) times; 128 = EOD.
    class RunLengthDecode
      include Base

      register_as "RunLengthDecode"

      class << self
        def decoder(bytes, _parms, _document)
          out = +""
          i = 0
          bs = bytes.bytes
          while i < bs.length
            n = bs[i]
            i += 1
            case n
            when 128 then break
            when 0..127
              out << bs[i, n + 1].pack("C*")
              i += n + 1
            when 129..255
              count = 257 - n
              out << (bs[i] || 0).chr * count if count.positive? && bs[i]
              i += 1
            end
          end
          out.force_encoding(Encoding::BINARY)
        end

        def encoder(bytes, _parms, _document)
          out = +""
          bs = bytes.bytes
          i = 0
          while i < bs.length
            # Try to find a run of identical bytes (3+).
            run_len = 1
            while i + run_len < bs.length && bs[i + run_len] == bs[i] && run_len < 128
              run_len += 1
            end
            if run_len >= 3
              out << (257 - run_len).chr
              out << bs[i].chr
              i += run_len
            else
              # Accumulate literals until next run or 128 bytes.
              literal = []
              while i < bs.length && literal.length < 128
                # Stop if a run of >= 3 starts.
                ahead_run = 0
                while i + ahead_run < bs.length && bs[i + ahead_run] == bs[i] && ahead_run < 3
                  ahead_run += 1
                end
                break if ahead_run >= 3

                literal << bs[i]
                i += 1
              end
              out << (literal.length - 1).chr
              out << literal.pack("C*")
            end
          end
          out << 128.chr # EOD
          out.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
