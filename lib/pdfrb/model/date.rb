# frozen_string_literal: true

require "time"

module Pdfrb
  module Model
    # PDF date (s7.9.4): `D:YYYYMMDDHHmmSSOHH'mm'` string.
    # Immutable value object wrapping a +Time+.
    class Date
      # Tolerates missing fields and the historical quirks Adobe
      # parsers accept in the wild.
      REGEX = /\A\s*D?:?(\d{4})(\d\d)?(\d\d)?(\d\d)?(\d\d)?(\d\d)?(Z|[+-])?(?:(\d+)(?:'|'(\d+)'?'?)?)?\s*\z/.freeze

      private_constant :REGEX

      attr_reader :time

      def initialize(time)
        @time = time
        freeze
      end

      def self.parse(str)
        return new(str) if str.is_a?(::Time)
        return nil if str.nil?
        return nil if str.is_a?(::String) && str.empty?

        unless str.is_a?(::String) && (m = REGEX.match(str))
          raise Pdfrb::ParseError, "invalid PDF date: #{str.inspect}"
        end

        sign = m[7]
        utc_offset =
          if sign.nil? || sign == "Z"
            0
          else
            mul = sign == "-" ? -1 : 1
            (m[8].to_i * 3600 + m[9].to_i * 60) * mul
          end

        ::Time.new(
          m[1].to_i,
          m[2] ? m[2].to_i.clamp(1, 12) : 1,
          m[3] ? m[3].to_i.clamp(1, 31) : 1,
          m[4].to_i.clamp(0, 23),
          m[5].to_i.clamp(0, 59),
          m[6].to_i.clamp(0, 59),
          utc_offset
        )
      end

      def self.format(time)
        off = time.utc_offset
        sign = off >= 0 ? "+" : "-"
        aoff = off.abs
        oh = aoff / 3600
        om = (aoff % 3600) / 60
        "D:%04d%02d%02d%02d%02d%02d%s%02d'%02d'" % [
          time.year, time.month, time.day, time.hour, time.min, time.sec,
          sign, oh, om
        ]
      end

      def to_s
        self.class.format(@time)
      end

      def ==(other)
        case other
        when Date then @time == other.time
        when ::Time then @time == other
        else false
        end
      end
      alias eql? ==

      def hash
        @time.hash
      end
    end
  end
end
