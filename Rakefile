# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "Cross-check PDF/A output against veraPDF (needs verapdf on PATH)"
task :verapdf do
  require "pdfrb"
  require "stringio"
  check = Pdfrb::Task::VeraPdfCrossCheck
  abort "verapdf not found on PATH (brew install verapdf)" unless check.available?

  font = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
  ].find { |path| File.file?(path) }
  abort "no system TTF found" unless font

  doc = Pdfrb::Document.new
  doc.enable_pdf_a!(part: 2, conformance: "B")
  font_obj = doc.fonts.add(font)
  doc.pages.add.canvas.text("veraPDF cross-check", at: [72, 720],
                                                   font: font_obj, size: 24)
  io = StringIO.new
  doc.write(io: io)

  result = check.call(io.string, flavour: :a2b)
  puts "profile:    #{result.profile}"
  puts "checks:     #{result.passed_checks} passed, #{result.failed_checks} failed"
  puts "size:       #{io.string.bytesize} bytes"
  result.failures.each { |f| puts "  #{f.clause}: #{f.message}" }
  abort "NOT PDF/A-2b COMPLIANT" unless result.compliant?
  puts "PDF/A-2b COMPLIANT"
end

namespace :arlington do
  desc "Re-vendor the Arlington TSVs from ~/src/pdfa/arlington-pdf-model/tsv/latest"
  task :refresh do
    require "fileutils"

    source = File.expand_path("~/src/pdfa/arlington-pdf-model/tsv")
    dest_root = File.expand_path("data/pdfrb/arlington", __dir__)

    unless File.directory?(source)
      warn "Arlington source not found at #{source}"
      exit 1
    end

    FileUtils.rm_rf(dest_root)
    FileUtils.cp_r(source, dest_root)
    puts "Refreshed Arlington TSVs -> #{dest_root}"
  end
end

namespace :fixtures do
  desc "Pull fixture corpus from claricle/pdf-core-examples"
  task :pull do
    token = ENV["CLARICLE_CI_PAT_TOKEN"] || ENV["GH_TOKEN"]
    if token.nil? || token.empty?
      warn "No CLARICLE_CI_PAT_TOKEN set — skipping fixture pull"
      next
    end
    dir = File.expand_path("spec/fixtures/pdf-core-examples", __dir__)
    FileUtils.rm_rf(dir) if Dir.exist?(dir)
    system("git clone --depth 1 " \
           "https://x-access-token:#{token}@github.com/claricle/pdf-core-examples " \
           "#{dir}") || warn("Failed to clone fixture corpus")
  end
end
