# frozen_string_literal: true

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
