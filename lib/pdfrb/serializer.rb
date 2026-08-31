# frozen_string_literal: true

module Pdfrb
  # Model -> PDF bytes (COS values). Stateless; safe to share across
  # documents. Indirect-object aware: a +Model::Reference+ value is
  # emitted as `oid gen R`, not inlined.
  #
  # Streams are emitted only as part of an indirect object via the
  # +Writer+ (which handles `obj`/`endobj` framing); the Serializer's
  # job is to produce the COS-fragment bytes for the dict body, the
  # stream payload, etc.
  class Serializer
    attr_reader :encrypter, :compress_streams, :compress_min_size

    def initialize(encrypter: nil, compress_streams: false, compress_min_size: 256)
      @encrypter = encrypter
      @compress_streams = compress_streams
      @compress_min_size = compress_min_size.to_i
    end

    class << self
      def serialize(value, encrypter: nil, **)
        new(encrypter: encrypter, **).serialize(value)
      end
    end

    def serialize(value)
      case value
      when ::Integer then serialize_integer(value)
      when ::Float then serialize_real(value)
      when ::Symbol then serialize_name(value)
      when ::String then serialize_string(value)
      when true then "true"
      when false then "false"
      when nil then "null"
      when Pdfrb::Model::Reference then serialize_reference(value)
      when ::Array then serialize_array(value)
      when Pdfrb::Model::PdfArray then serialize_array(value.value)
      when ::Hash then serialize_dict(value)
      when Pdfrb::Model::Cos::Dictionary then serialize_dict(value.value)
      when Pdfrb::Model::Cos::Stream then serialize_dict(value.value)
      when Pdfrb::Model::Object then serialize(value.value)
      when Pdfrb::Model::Date then serialize_date_string(value)
      when Pdfrb::Model::Rectangle then serialize_array(value.to_a)
      when Pdfrb::Model::Matrix then serialize_array(value.to_a)
      else
        raise Pdfrb::SerializeError,
              "cannot serialise #{value.class}: #{value.inspect}"
      end
    end

    # Serialise an indirect object's body, including `oid gen obj`
    # header and (for streams) the stream payload. When an encrypter
    # is set, all strings in the object's dictionaries and the stream
    # payload are encrypted with the per-object key (s7.6.1) — pass
    # +skip_encryption:+ for objects that must stay readable: the
    # /Encrypt dictionary itself (s7.6.3) and cross-reference streams.
    def serialize_indirect(obj, skip_encryption: false)
      raise ArgumentError, "not indirect: #{obj.inspect}" unless obj.indirect?

      encrypt_strings = !skip_encryption && encrypter
      buffer = +""
      buffer << "#{obj.oid} #{obj.gen} obj\n"
      case obj
      when Pdfrb::Model::Cos::Stream
        dict_value = encrypt_strings ? Pdfrb::Encryption::ValueStrings.encrypt(obj.value, obj.oid, obj.gen, encrypter) : obj.value
        dict, payload = emit_stream(obj, dict_value)
        buffer << dict
        buffer << "\nstream\n"
        buffer << (encrypter && !skip_encryption ? encrypter.encrypt_stream(payload, obj.oid, obj.gen) : payload)
        buffer << "\nendstream\n"
      else
        value = encrypt_strings ? Pdfrb::Encryption::ValueStrings.encrypt(obj.value, obj.oid, obj.gen, encrypter) : obj.value
        buffer << serialize(value)
        buffer << "\n"
      end
      buffer << "endobj\n"
      buffer.force_encoding(Encoding::BINARY)
    end

    private

    # Build the dict body + payload for a stream object, applying
    # FlateDecode compression when enabled and the stream is large
    # enough to benefit. Returns [dict_bytes, payload_bytes].
    def emit_stream(stream_obj, dict_value = stream_obj.value)
      payload = stream_obj.stream
      hash = dict_value.dup
      existing_filter = hash[:Filter]

      if should_compress?(stream_obj, payload, existing_filter)
        compressed = compress_bytes(payload)
        if compressed.bytesize < payload.bytesize
          hash[:Filter] = combine_filters(existing_filter, :FlateDecode)
          hash[:Length] = compressed.bytesize
          return [serialize_dict(hash), compressed]
        end
      end

      hash[:Length] = payload.bytesize
      [serialize_dict(hash), payload]
    end

    def should_compress?(stream_obj, payload, existing_filter)
      return false unless @compress_streams
      return false if existing_filter # caller knows what they want
      return false if stream_obj.value[:Type] == :XRef # spec-recommended uncompressed
      return false if payload.bytesize < @compress_min_size

      true
    end

    def combine_filters(existing, new_filter)
      existing ? [existing, new_filter] : new_filter
    end

    def compress_bytes(bytes)
      require "zlib"
      wio = StringIO.new((+"").force_encoding(Encoding::BINARY))
      w = Zlib::Deflate.new(9)
      wio.write(w.deflate(bytes, Zlib::FINISH))
      w.close
      wio.string
    end

    def serialize_integer(n)
      n.to_s
    end

    def serialize_real(f)
      # Minimal round-trippable form.
      s = f.to_s
      s = s.sub(/\.0+\z/, "") if s.match?(/\A-?\d+\.0+\z/)
      s
    end

    def serialize_name(sym)
      Pdfrb::Model::Cos::NameEncoding.encode(sym)
    end

    def serialize_string(str)
      bytes = if str.encoding == Encoding::UTF_8
                Pdfrb::Model::Cos::StringEncoding.encode_text(str)
              else
                str.dup.force_encoding(Encoding::BINARY)
              end
      body = bytes.gsub(/[\\()]/) { |c| "\\#{c}" }
      "(#{body})".b
    end

    def serialize_reference(ref)
      "#{ref.oid} #{ref.gen} R"
    end

    def serialize_array(arr)
      inner = arr.map { |v| serialize(v) }.join(" ")
      "[#{inner}]"
    end

    def serialize_dict(hash)
      inner = hash.each_with_object(+"") do |(k, v), buf|
        next if k == :Stream # not a real key, just metadata

        buf << serialize_name(k) << " " << serialize(v) << "\n"
      end
      "<<\n#{inner}>>".b
    end

    def serialize_dict_with_length(stream)
      # Always (re)set /Length to match the actual stream byte count.
      hash = stream.value.dup
      hash[:Length] = stream.stream.bytesize
      serialize_dict(hash)
    end

    def serialize_date_string(date)
      body = date.to_s
      "(#{body})".b
    end
  end
end
