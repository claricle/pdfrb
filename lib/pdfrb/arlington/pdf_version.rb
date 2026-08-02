# frozen_string_literal: true

module Pdfrb
  module Arlington
    # PDF version value object. Comparable by [major, minor]. Handles
    # the 9 canonical versions (1.0..1.7, 2.0) plus predicate-wrapped
    # variants (`fn:Extension(name, version)`, `fn:Eval(expr)`).
    #
    # For predicate-wrapped versions, the +literal+ is the version
    # embedded in the predicate; +extensions+ captures the named
    # extension(s) attached. Evaluator-side predicate handling decides
    # whether an extension applies to a given document.
    class PdfVersion
      include Comparable

      CANONICAL = %w[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.0].freeze

      attr_reader :major, :minor, :literal, :extensions

      def initialize(version, extensions: [])
        case version
        when PdfVersion
          @major = version.major
          @minor = version.minor
          @literal = version.literal
          @extensions = version.extensions
        when ::String
          @literal = parse_literal(version)
          @major, @minor = parse_major_minor(@literal)
          @extensions = extensions
        else
          raise ArgumentError, "PdfVersion needs a String, got #{version.class}"
        end
        freeze
      end

      def self.latest; new("2.0"); end

      # Parse a TSV cell. Tolerates:
      #   "1.7"                          -> 1.7
      #   "fn:Extension(ISO_19005_3,1.7)" -> 1.7 + extension ISO_19005_3
      #   "fn:Eval(...)"                  -> latest (caller resolves via predicate)
      def self.from_tsv_cell(str)
        return nil if str.nil? || str.empty?

        s = str.strip
        case s
        when /\A(\d+\.\d+)\z/
          new(Regexp.last_match(1))
        when /\Afn:Extension\(([^,]+),\s*(\d+\.\d+)\)\z/
          new(Regexp.last_match(2), extensions: [Regexp.last_match(1)])
        when /\Afn:Extension\(([^,)]+)\)\z/
          # name-only extension (e.g. fn:Extension(OpenOffice)) — no version.
          new("2.0", extensions: [Regexp.last_match(1)])
        when /\Afn:Eval\(/, /\Afn:SinceVersion\(/, /\Afn:IsPDFVersion\(/
          new("2.0", extensions: [:predicate]) # caller resolves via predicate
        else
          raise Pdfrb::ParseError, "unrecognised PDF version: #{str.inspect}"
        end
      end

      def to_s
        "#{@major}.#{@minor}"
      end

      def to_a
        [@major, @minor]
      end

      def <=>(other)
        return nil unless other.is_a?(PdfVersion)

        to_a <=> other.to_a
      end

      def hash
        to_a.hash
      end

      def eql?(other)
        other.is_a?(PdfVersion) && to_a == other.to_a
      end
      alias == eql?

      def since?(other)
        self >= other
      end

      def before?(other)
        self < other
      end

      def deprecated_at?(deprecated_in)
        return false unless deprecated_in

        self >= deprecated_in
      end

      def predicate_wrapped?
        @extensions == [:predicate]
      end

      private

      def parse_literal(str)
        return str if str.match?(/\A\d+\.\d+\z/)

        # Caller should use from_tsv_cell for predicate forms; we tolerate
        # by returning a sensible default.
        str.match?(/\A\d+(\.\d+)?\z/) ? str : "2.0"
      end

      def parse_major_minor(str)
        m = str.match(/\A(\d+)\.(\d+)\z/)
        raise ArgumentError, "bad version #{str.inspect}" unless m

        [m[1].to_i, m[2].to_i]
      end
    end
  end
end
