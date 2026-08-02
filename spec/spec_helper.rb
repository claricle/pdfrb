# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/pkg/"
    add_filter "/data/"
    add_group "Source", "lib/pdfrb/source"
    add_group "Model", "lib/pdfrb/model"
    add_group "Filters", "lib/pdfrb/filter"
    add_group "Content", "lib/pdfrb/content"
    add_group "Font", "lib/pdfrb/font"
    add_group "Encryption", "lib/pdfrb/encryption"
    add_group "Tasks", "lib/pdfrb/task"
    add_group "CLI", "lib/pdfrb/cli.rb"
    add_group "Document facade", "lib/pdfrb/document"
    minimum_coverage 50
    minimum_coverage_by_file 10
  end
end

require "pdfrb"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module PdfrbSpecHelpers
  def fixture_path(*segments)
    File.join(__dir__, "fixtures", *segments)
  end

  def read_fixture(*segments)
    File.binread(fixture_path(*segments))
  end
end

RSpec.configure { |c| c.include PdfrbSpecHelpers }
