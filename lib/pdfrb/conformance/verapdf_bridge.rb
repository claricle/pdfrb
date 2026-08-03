# frozen_string_literal: true

require "open3"
require "tempfile"
require "stringio"

module Pdfrb
  module Conformance
    # Bridge to veraPDF for authoritative PDF/A validation. veraPDF
    # is the official open-source PDF/A conformance checker.
    #
    # If veraPDF is not installed, all methods return a Result with
    # `available: false`. Install veraPDF from https://verapdf.org/.
    #
    # Usage:
    #   result = Pdfrb::Conformance::VeraPdfBridge.validate(pdf_bytes, profile: "1b")
    #   result.passed?
    class VeraPdfBridge
      Result = Struct.new(:available, :passed, :violations, :raw_output,
                          keyword_init: true) do
        def passed?
          available && self[:passed]
        end
      end

      Violation = Struct.new(:rule_id, :message, :spec_clause, keyword_init: true)

      class << self
        def available?
          _, status = Open3.capture2e("verapdf --version")
          status.success?
        rescue StandardError
          false
        end

        def validate(pdf_bytes, profile: "2b")
          return Result.new(available: false) unless available?

          Tempfile.create(["pdfrb", ".pdf"], binmode: true) do |file|
            file.write(pdf_bytes)
            file.flush

            output, status = Open3.capture2e("verapdf --profile #{profile} --format json #{file.path}")

            Result.new(
              available: true,
              passed: status.success?,
              violations: parse_violations(output),
              raw_output: output
            )
          end
        rescue StandardError => e
          Result.new(available: false, raw_output: e.message)
        end

        def parse_violations(json_output)
          return [] unless json_output && !json_output.empty?

          require "json"
          data = safe_parse(json_output)
          return [] unless data

          assertions = dig_string_path(data, ["report", "jobs", 0, "validationResult", "details", "assertions"])
          return [] unless assertions

          assertions.map do |a|
            Violation.new(
              rule_id: a["ruleId"],
              message: a["message"],
              spec_clause: a["clause"]
            )
          end
        end

        def dig_string_path(hash, path)
          path.reduce(hash) do |current, key|
            case current
            when ::Hash then current[key]
            when ::Array then key.is_a?(::Integer) ? current[key] : nil
            end
          end
        end

        def safe_parse(json_output)
          JSON.parse(json_output)
        rescue StandardError
          nil
        end
      end
    end
  end
end
