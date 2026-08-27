# frozen_string_literal: true

require "fileutils"
require "open3"
require "stringio"

module Pdfrb
  module Task
    # Cross-check pdfrb's PDF/A output against the veraPDF validator
    # (the reference implementation for ISO 19005 conformance).
    #
    # Runs the +verapdf+ binary over a PDF file and parses the XML
    # report. The binary path is configurable via VERAPDF_BIN or the
    # +binary:+ argument for CI environments that download a release.
    module VeraPdfCrossCheck
      Result = Struct.new(
        :compliant, :passed_rules, :failed_rules,
        :passed_checks, :failed_checks, :failures, :raw, :profile
      ) do
        def compliant?
          compliant == true
        end

        def failure_messages
          failures.map(&:message)
        end
      end

      Failure = Struct.new(:clause, :description, :message, :context)

      FLAVOURS = {
        a1b: "1b", a1a: "1a", a2b: "2b", a2a: "2a", a2u: "2u",
        a3b: "3b", a3a: "3a", a3u: "3u", a4b: "4b", a4f: "4f",
        a4e: "4e", u1a: "ua1", u2a: "ua2", u3a: "ua3"
      }.freeze

      module_function

      # @param pdf [String, #read] path to a PDF file, or IO/bytes.
      # @param flavour [Symbol, String] veraPDF flavour key (:a2b) or
      #   raw code ("2b").
      # @param binary [String] verapdf executable path.
      # @return [Result]
      def call(pdf, flavour: :a2b, binary: ENV.fetch("VERAPDF_BIN", "verapdf"))
        flavour_code = FLAVOURS.fetch(flavour.to_sym, flavour.to_s)
        path, tempdir = materialise(pdf)
        out, err, status = Open3.capture3(binary, "--flavour", flavour_code, path)

        report = parse_report(out) if status.success? || out.include?("<report")
        report || raise(Pdfrb::Error,
                        "verapdf failed (#{status.exitstatus}): #{err[0, 200]}")
      ensure
        FileUtils.remove_entry(tempdir) if tempdir
      end

      # True when the verapdf binary is available.
      def available?(binary: ENV.fetch("VERAPDF_BIN", "verapdf"))
        _out, _err, status = Open3.capture3(binary, "--version")
        status.success?
      rescue Errno::ENOENT
        false
      end

      def parse_report(xml)
        require "rexml/document"
        doc = REXML::Document.new(xml)

        validation = REXML::XPath.first(doc, "//validationReport")
        details = REXML::XPath.first(doc, "//validationReport/details")
        result = Result.new(
          validation&.[]("isCompliant") == "true",
          details&.[]("passedRules").to_i,
          details&.[]("failedRules").to_i,
          details&.[]("passedChecks").to_i,
          details&.[]("failedChecks").to_i,
          [], xml, validation&.[]("profileName").to_s
        )

        REXML::XPath.each(doc, "//rule[@status='failed']") do |rule|
          description = rule.elements["description"]&.text.to_s.strip
          clause = "#{rule.attributes['specification']} " \
                   "cl.#{rule.attributes['clause']}.#{rule.attributes['testNumber']}"
          REXML::XPath.each(rule, ".//check[@status='failed']") do |check|
            result.failures << Failure.new(
              clause, description,
              check.elements["errorMessage"]&.text.to_s.strip,
              check.elements["context"]&.text.to_s.strip
            )
          end
        end
        result
      end

      # Returns [path, tempdir-or-nil]; the caller removes tempdir.
      def materialise(pdf)
        if pdf.is_a?(String) && !pdf.include?("\0") && File.file?(pdf)
          return [pdf, nil]
        end

        bytes = pdf.is_a?(String) ? pdf : pdf.read
        require "tmpdir"
        tempdir = Dir.mktmpdir("verapdf")
        path = File.join(tempdir, "check.pdf")
        File.binwrite(path, bytes)
        [path, tempdir]
      end
    end
  end
end
