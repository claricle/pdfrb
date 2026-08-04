# frozen_string_literal: true

module Pdfrb
  class CLI
    module Info
      module_function

      def call(path)
        doc = Pdfrb::Document.open(path)
        puts "File: #{path}"
        puts "Version: #{doc.version}"
        puts "Pages: #{doc.pages.count}"
        puts "Encrypted: #{!doc.trailer&.[](:Encrypt).nil?}"
        puts "Title: #{doc.metadata[:Title]}" if doc.metadata[:Title]
        puts "Author: #{doc.metadata[:Author]}" if doc.metadata[:Author]
        true
      end
    end
  end
end
