# frozen_string_literal: true

module Pdfrb
  # Base class for every Pdfrb error. Rescue this to catch anything the
  # gem raises. Subclasses carry typed metadata about the failure.
  class Error < StandardError; end

  # Lexing or parsing the byte stream failed. Carries +source_position+
  # (a [line, column] pair or byte offset) when known.
  class ParseError < Error
    attr_reader :source_position

    def initialize(message, source_position: nil)
      @source_position = source_position
      super(message)
    end
  end

  # Lexer hit a byte or construct it could not consume (bad hex digit,
  # unterminated string literal, invalid number, etc.).
  class LexError < ParseError; end

  # Tokens did not form a valid PDF structure (unbalanced << >>,
  # missing endobj, malformed xref, etc.).
  class SyntaxError < ParseError; end

  # A PDF file violates the spec but Pdfrb recovered (or attempted to).
  # +recovered?+ tells the caller whether reconstruction succeeded.
  class MalformedPdfError < ParseError
    attr_reader :recovered

    def initialize(message, recovered: false, **opts)
      @recovered = recovered
      super(message, **opts)
    end

    def recovered? = @recovered
  end

  # Model -> bytes serialization failed.
  class SerializeError < Error; end

  # A stream filter (FlateDecode, LZWDecode, ...) failed to decode or
  # encode. Carries +filter_name+.
  class FilterError < Error
    attr_reader :filter_name

    def initialize(message, filter_name: nil)
      @filter_name = filter_name
      super(message)
    end
  end

  # Encryption setup, decryption, or encryption failed. Subclassed
  # further by the Encryption namespace as needed (DecryptionError,
  # UnsupportedEncryptionError).
  class EncryptionError < Error; end

  # PDF version requested or detected is not supported by Pdfrb.
  class UnsupportedVersionError < Error
    attr_reader :version

    def initialize(message, version: nil)
      @version = version
      super(message)
    end
  end

  # An indirect reference could not be resolved (dangling pointer,
  # wrong generation, free list, corrupt xref entry).
  class ObjectReferenceError < Error
    attr_reader :oid, :gen

    def initialize(message, oid: nil, gen: nil)
      @oid = oid
      @gen = gen
      super(message)
    end
  end

  # An Arlington predicate or field-level validation rule fired.
  # Carries +field_name+ and +predicate_name+ for diagnostics.
  class ValidationError < Error
    attr_reader :field_name, :predicate_name

    def initialize(message, field_name: nil, predicate_name: nil)
      @field_name = field_name
      @predicate_name = predicate_name
      super(message)
    end
  end
end
