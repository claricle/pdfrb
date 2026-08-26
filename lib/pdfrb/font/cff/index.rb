# frozen_string_literal: true

module Pdfrb
  module Font
    module CFF
      # CFF INDEX structure (TN5176 s5): count (Card16), offSize
      # (OffSize), offsets (count+1 × offSize bytes, 1-based), then
      # the data items.
      class Index
        attr_reader :items

        # Parse an INDEX at +offset+ in +data+; returns [index,
        # next_offset].
        def self.parse(data, offset)
          count = data.byteslice(offset, 2).unpack1("n")
          return [new([]), offset + 2] if count.zero?

          off_size = data.getbyte(offset + 2)
          offsets_base = offset + 3
          offsets = (0..count).map do |i|
            read_off(data, offsets_base + (i * off_size), off_size)
          end
          data_base = offsets_base + ((count + 1) * off_size)
          items = (0...count).map do |i|
            start = data_base + offsets[i] - 1
            len = offsets[i + 1] - offsets[i]
            data.byteslice(start, len)
          end
          [new(items), data_base + offsets[count] - 1]
        end

        def self.read_off(data, pos, size)
          value = 0
          size.times { |i| value = (value * 256) + data.getbyte(pos + i) }
          value
        end

        def initialize(items)
          @items = items
        end

        def each(&)
          @items.each(&)
        end

        def size
          @items.size
        end

        def [](i)
          @items[i]
        end

        # Serialize back to INDEX bytes.
        def serialize
          return [0].pack("n") if @items.empty?

          offsets = [1]
          @items.each { |item| offsets << (offsets.last + item.bytesize) }
          max = offsets.last
          off_size = if max < 0x100
                       1
                     else
                       (if max < 0x10000
                          2
                        else
                          (max < 0x1000000 ? 3 : 4)
                        end)
                     end

          buf = +"".b
          buf << [@items.size].pack("n")
          buf << off_size.chr
          offsets.each do |o|
            off_size.downto(1) { |i| buf << ((o >> (8 * (i - 1))) & 0xFF).chr }
          end
          @items.each { |item| buf << item.b }
          buf
        end
      end
    end
  end
end
