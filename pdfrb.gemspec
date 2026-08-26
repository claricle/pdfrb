# frozen_string_literal: true

require_relative "lib/pdfrb/version"

Gem::Specification.new do |spec|
  spec.name = "pdfrb"
  spec.version = Pdfrb::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Pure-Ruby PDF parser, Arlington-model-driven domain model, and serializer"
  spec.description = <<~HEREDOC
    Pdfrb is a pure-Ruby PDF library: a byte-level reader, an
    Arlington-model-driven typed domain model, and a serializer. The
    PDF object model is sourced directly from the vendored Arlington
    PDF Model TSVs (machine-readable ISO 32000-2:2020), so field
    metadata, version predicates, and validators stay aligned with
    the spec by data, not by hand-coded mimicry.

    Two-direction contract: "PDF file <=> Model" and "API Builder
    Input => Model". Mirrors the layered design of the sibling
    postscript gem.
  HEREDOC

  spec.homepage = "https://github.com/claricle/pdfrb"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/claricle/pdfrb"
  spec.metadata["changelog_uri"] = "https://github.com/claricle/pdfrb/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/claricle/pdfrb/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark", "~> 0.4"
  spec.add_dependency "logger", "~> 1.6"
  spec.add_dependency "thor"
end
