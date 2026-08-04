# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Name
        attr_reader :format, :count, :records

        def initialize(data)
          return unless data && data.bytesize >= 6

          @format = u16(data, 0)
          @count = u16(data, 2)
          string_offset = u16(data, 4)
          @records = {}

          @count.times do |i|
            offset = 6 + i * 12
            break if offset + 12 > data.bytesize

            platform_id = u16(data, offset)
            encoding_id = u16(data, offset + 2)
            _lang_id = u16(data, offset + 4)
            name_id = u16(data, offset + 6)
            length = u16(data, offset + 8)
            str_offset = u16(data, offset + 10)

            next unless [1, 3].include?(platform_id)

            raw = data.byteslice(string_offset + str_offset, length)
            next unless raw

            str = if platform_id == 3
                    raw.bytes.each_slice(2).map { |b| (b[0] << 8) | (b[1] || 0) }.pack("U*")
                  else
                    raw.force_encoding("UTF-8")
                  end
            @records[name_id] = str
          end
        end

        def family; @records[1] || @records[16]; end
        def subfamily; @records[2] || @records[17]; end
        def ps_name; @records[6]; end
        def full_name; @records[4]; end

        private

        def u16(data, off); (data.getbyte(off) << 8) | data.getbyte(off + 1); end
      end
    end
  end
end
