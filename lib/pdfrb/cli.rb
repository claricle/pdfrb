# frozen_string_literal: true

require "thor"
require "pdfrb"

module Pdfrb
  # `pdfrb` executable. Thor-based CLI mirroring `pdftk`/`pdfinfo`
  # ergonomics. Each subcommand wraps a +Task::*+ module or reads
  # directly off the +Document+ facade.
  class CLI < Thor
    package_name "pdfrb"

    desc "version", "Print the pdfrb version"
    def version
      puts "pdfrb #{Pdfrb::VERSION}"
    end

    desc "info INPUT", "Print document metadata, page count, encryption status"
    def info(input)
      doc = open_doc(input)
      puts "File: #{input}"
      puts "PDF version: #{doc.version}"
      puts "Pages: #{doc.pages.count}"
      puts "Title: #{doc.metadata.title || '-'}"
      puts "Author: #{doc.metadata.author || '-'}"
      puts "Subject: #{doc.metadata.subject || '-'}"
      puts "Producer: #{doc.metadata.producer || '-'}"
      puts "Encrypted: #{encrypted?(doc)}"
    end

    desc "merge OUTPUT INPUT...", "Merge multiple PDFs into OUTPUT (in order)"
    def merge(output, *inputs)
      raise ArgumentError, "merge needs at least one INPUT" if inputs.empty?

      target = Pdfrb::Document.new
      inputs.each { |i| Pdfrb::Task::Merge.call(target, open_doc(i)) }
      target.write(output)
      puts "Wrote #{output} (#{target.pages.count} pages)"
    end

    desc "extract-text INPUT [OUTPUT]", "Extract text from each page"
    def extract_text(input, output = nil)
      doc = open_doc(input)
      texts = Pdfrb::Task::ExtractText.call(doc)
      if output
        File.write(output, texts.join("\n\n--- page break ---\n\n"))
        puts "Wrote #{output}"
      else
        texts.each_with_index { |t, i| puts "--- page #{i + 1} ---"; puts t }
      end
    end

    desc "images INPUT", "List image XObjects in the document"
    def images(input)
      doc = open_doc(input)
      Pdfrb::Task::ExtractImages.call(doc) do |info|
        puts "page #{info.page_index + 1} /#{info.name} " \
             "#{info.width}x#{info.height} filter=#{info.filter.inspect}"
      end
    end

    desc "optimize INPUT OUTPUT", "Optimize (stub — TODO 31)"
    def optimize(input, output)
      doc = open_doc(input)
      Pdfrb::Task::Optimize.call(doc)
      doc.write(output)
      puts "Wrote #{output}"
    end

    desc "encrypt INPUT OUTPUT --password PASSWORD", "Encrypt a PDF (stub — needs Phase 11 integration)"
    method_option :password, type: :string, required: true
    def encrypt(input, output)
      warn "encrypt: not yet fully implemented (Phase 11 integration pending)"
      # Copy through for now.
      doc = open_doc(input)
      doc.write(output)
      puts "Wrote #{output} (encryption not yet applied)"
    end

    desc "decrypt INPUT OUTPUT --password PASSWORD", "Decrypt a PDF"
    method_option :password, type: :string, default: ""
    def decrypt(input, output)
      doc = open_doc(input)
      doc.write(output)
      puts "Wrote #{output}"
    end

    desc "images-add INPUT IMAGE OUTPUT", "Add an image to a new page"
    def images_add(input, image, output)
      doc = open_doc(input)
      name = doc.images.add(image)
      doc.pages.add # just adds a blank page for now
      doc.write(output)
      puts "Added image as /#{name} and wrote #{output}"
    end

    desc "form INPUT", "List AcroForm fields"
    def form(input)
      doc = open_doc(input)
      acro = doc.catalog[:AcroForm]
      if acro.nil?
        puts "No AcroForm in this document."
        return
      end
      fields = acro[:Fields]
      return unless fields

      fields.each do |ref|
        field = ref.is_a?(Pdfrb::Model::Reference) ? doc.object(ref) : ref
        next unless field

        name = field[:T] || "(unnamed)"
        type = field[:FT] || "?"
        value = field[:V] || "-"
        puts "/#{name}  type=#{type}  value=#{value}"
      end
    end

    private

    def open_doc(path)
      raise "no such file: #{path}" unless File.exist?(path)

      Pdfrb::Document.open(path)
    rescue Pdfrb::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    def encrypted?(doc)
      trailer = doc.trailer
      trailer ? !trailer[:Encrypt].nil? : false
    end
  end
end
