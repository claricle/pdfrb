# frozen_string_literal: true

module Pdfrb
  # PDF lexical and structural constants. Sourced from ISO 32000-2:2020
  # subclause 7.2 ("Lexical Conventions"). These are the bytes and
  # tokens the Tokenizer operates on.
  module PdfConstants
    # The header magic every PDF file begins with (after optional BOM
    # or leading whitespace, which the spec discourages but tolerates).
    HEADER_PREFIX = "%PDF-"

    # Binary-marketing comment recommended after the header so tools
    # that sniff for binary content treat the file correctly.
    BINARY_MARKER = "%\xE2\xE3\xCF\xD3".b

    # End-of-file marker (technically just a comment, but conventional).
    EOF_MARKER = "%%EOF"

    # Whitespace bytes per s7.2.2. NUL, TAB, LF, FF, CR, SPACE.
    WHITESPACE = "\x00\t\n\f\r ".b

    # Delimiter bytes per s7.2.2.
    DELIMITERS = "()<>[]{}/%".b

    # Bytes that terminate a name token, a number, or a keyword.
    TERMINATORS = (WHITESPACE + DELIMITERS).b

    # PDF versions Pdfrb recognises, sorted oldest to newest. The
    # Arlington model defines the canonical version set; this is its
    # Ruby mirror.
    PDF_VERSIONS = %w[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.0].freeze

    # Latest PDF version Pdfrb fully understands. Versions newer than
    # this raise UnsupportedVersionError on read.
    LATEST_VERSION = "2.0"

    # PDF "object" grammar keywords the Tokenizer treats specially.
    KEYWORDS = %w[
      obj endobj stream endstream xref startxref trailer true false null
    ].freeze
  end
end
