# frozen_string_literal: true

module Pdfrb
  # Per-Document configuration. A frozen Hash-with-defaults that can be
  # deep-merged with user overrides. Mirrors HexaPDF::Configuration in
  # shape, but starts minimal — settings get added as features land.
  class Configuration
    DEFAULTS = {
      # When true, malformed PDFs are recovered heuristically instead
      # of raising MalformedPdfError. Production readers should keep
      # this true; strict validators can flip it off.
      "source.recover_malformed" => true,

      # When true, an encrypted PDF is decrypted on open (using
      # decryption_opts passed to Document.new). Disable for raw
      # inspection of ciphertext.
      "document.auto_decrypt" => true,

      # Callback invoked when a string field has an invalid encoding.
      # Default: replace with U+FFFD in UTF-8.
      "document.on_invalid_string" => ->(str) { str.encode("UTF-8", invalid: :replace, undef: :replace) },

      # When true, errors that Pdfrb can auto-correct are raised after
      # all (so test runs catch corruption). Production readers flip
      # this off.
      "parser.on_correctable_error" => ->(_doc, _msg) { false },

      # When true, Stream objects larger than writer.compress_min_size
      # are emitted with /Filter /FlateDecode on write. Existing
      # /Filter values are honoured (no double compression).
      "writer.compress_streams" => false,
      "writer.compress_min_size" => 256,

      # When true, write an XRef stream (PDF 1.5+) instead of a
      # classical xref table. Enables compressed-object references.
      "writer.use_xref_stream" => false,

      # When true, pack eligible small objects into /Type /ObjStm
      # streams. Reduces file size 20-50%. Requires xref stream.
      "writer.pack_object_streams" => false,

      # Objects smaller than this (serialized bytes) are eligible
      # for ObjStm packing.
      "writer.object_stream_threshold" => 200
    }.freeze

    attr_reader :settings

    def initialize(overrides = {})
      @settings = deep_merge(DEFAULTS.dup, overrides)
      freeze
    end

    def [](key)
      @settings[key]
    end

    def []=(key, value)
      @settings[key] = value
    end

    private

    def deep_merge(target, source)
      source.each do |k, v|
        target[k] =
          if target[k].is_a?(Hash) && v.is_a?(Hash)
            deep_merge(target[k], v)
          else
            v
          end
      end
      target
    end
  end
end
