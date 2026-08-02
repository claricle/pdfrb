# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

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
