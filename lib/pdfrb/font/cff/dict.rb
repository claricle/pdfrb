# frozen_string_literal: true

module Pdfrb
  module Font
    module CFF
      # DICT data parsing (TN5176 s4): a sequence of operands (from
      # the b0 byte ranges) followed by an operator byte.
      #
      # Used both to READ the Top DICT (CharStrings offset, Private
      # [size offset], charset) and to locate operator positions so a
      # subsetter can patch offsets in place.
      class Dict
        # One operator plus its trailing operands, with the byte
        # range it occupied in the source DICT.
        Entry = Struct.new(:operator, :operands, :start, :finish) do
          def int_operand(i = 0)
            v = operands[i]
            v.is_a?(Integer) ? v : nil
          end
        end

        attr_reader :entries, :raw

        def self.parse(data)
          entries = []
          operands = []
          pos = 0
          entry_start = 0
          while pos < data.bytesize
            b0 = data.getbyte(pos)
            case b0
            when 28 then operands << data.byteslice(pos + 1, 2).unpack1("n")
                         pos += 3
            when 29 then operands << data.byteslice(pos + 1, 4).unpack1("N")
                         pos += 5
            when 30
              real, pos = parse_real(data, pos + 1)
              operands << real
            when 32..246
              operands << (b0 - 139)
              pos += 1
            when 247..250
              operands << (((b0 - 247) * 256) + data.getbyte(pos + 1) + 108)
              pos += 2
            when 251..254
              operands << ((-(b0 - 251) * 256) - data.getbyte(pos + 1) - 108)
              pos += 2
            else
              # Operator (0..21, with 12 x for two-byte ops).
              if b0 == 12
                op = [12, data.getbyte(pos + 1)]
                pos += 2
              else
                op = b0
                pos += 1
              end
              entries << Entry.new(op, operands, entry_start, pos)
              operands = []
              entry_start = pos
            end
          end
          new(data, entries)
        end

        NIBBLE_CHARS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "E", "E-", nil, "-"].freeze
        private_constant :NIBBLE_CHARS

        # Real operand (b0 30): nibble-encoded decimal terminated by
        # 0xF. Returns [Float, next_pos].
        def self.parse_real(data, pos)
          buf = +""
          while pos < data.bytesize
            nibble_pair = data.getbyte(pos)
            pos += 1
            hi = nibble_pair >> 4
            lo = nibble_pair & 0xF
            break if hi == 0xF

            buf << NIBBLE_CHARS[hi]
            break if lo == 0xF

            buf << NIBBLE_CHARS[lo]
          end
          [buf.to_f, pos]
        end

        def initialize(raw, entries)
          @raw = raw
          @entries = entries
        end

        # Entry for a one-byte Integer operator or a two-byte
        # [12, x] operator.
        def entry_for(operator)
          entries.find { |e| e.operator == operator }
        end

        # Top DICT helpers (operator numbers per TN5176 Table 6):
        #   15 charset, 17 CharStrings, 18 Private [size offset].
        def charset_offset
          entry_for(15)&.int_operand
        end

        def charstrings_offset
          entry_for(17)&.int_operand
        end

        # Returns [size, offset].
        def private_size_offset
          e = entry_for(18)
          return nil unless e

          [e.int_operand(0), e.int_operand(1)]
        end
      end
    end
  end
end
