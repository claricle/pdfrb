# frozen_string_literal: true

module Pdfrb
  module Encryption
    # Pure-Ruby RC4 stream cipher (s7.6.3.1, Algorithm 1). Key can be
    # 1..256 bytes (PDF uses 5..32). Stateless per call: build a new
    # cipher for each (key, oid, gen) tuple.
    class RC4
      attr_reader :key

      def initialize(key)
        @key = key.b
        @s = (0..255).to_a
        @i = @j = 0
        key_schedule
      end

      # Encrypt/decrypt +bytes+ (symmetric). Caller is responsible for
      # prepending the per-object key (5..16 bytes derived via MD5 of
      # file_key + oid + gen).
      def process(bytes)
        out = +""
        bytes.b.each_byte do |b|
          @i = (@i + 1) & 0xFF
          @j = (@j + @s[@i]) & 0xFF
          @s[@i], @s[@j] = @s[@j], @s[@i]
          out << (b ^ @s[(@s[@i] + @s[@j]) & 0xFF]).chr
        end
        out.force_encoding(Encoding::BINARY)
      end
      alias encrypt process
      alias decrypt process

      private

      def key_schedule
        j = 0
        256.times do |i|
          j = (j + @s[i] + @key.getbyte(i % @key.bytesize)) & 0xFF
          @s[i], @s[j] = @s[j], @s[i]
        end
      end
    end
  end
end
