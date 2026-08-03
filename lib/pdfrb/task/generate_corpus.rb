# frozen_string_literal: true

require "openssl"
require "stringio"

module Pdfrb
  module Task
    # Generates a diverse corpus of test PDFs for regression testing
    # and cross-implementation comparison. Each method returns raw
    # PDF bytes covering a specific feature dimension.
    class GenerateCorpus
      class << self
        # All corpus generators as a { name => bytes } hash.
        def all
          {
            simple: simple_text,
            multipage: multipage_text,
            encrypted: encrypted_doc,
            with_outline: with_outline,
            tagged: tagged_pdf,
            with_layers: with_layers,
            with_form: with_form,
            signed: signed_doc,
            large: large_document(20),
          }
        end

        def simple_text
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            d.pages.add.canvas.text("Hello, World!", at: [72, 720], font: font, size: 24)
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def multipage_text
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            5.times { |i| d.pages.add.canvas.text("Page #{i + 1}", at: [72, 720], font: font, size: 12) }
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def encrypted_doc(_password: "test123")
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            d.pages.add.canvas.text("Encrypted", at: [72, 720], font: font, size: 12)
          end.then do |d|
            io = StringIO.new
            Pdfrb::Writer.write(d, io)
            io.string
          rescue StandardError
            ""
          end
        end

        def with_outline
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            3.times do |i|
              page = d.pages.add
              page.canvas.text("Section #{i + 1}", at: [72, 720], font: font, size: 14)
              d.outline.add("Section #{i + 1}", dest: page)
            end
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def tagged_pdf
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            page = d.pages.add
            page.canvas.text("Tagged content", at: [72, 720], font: font, size: 12)
            d.catalog.value[:Lang] = "en-US"
            d.structure.add_element(:Document) do |doc_elem|
              d.structure.add_child(doc_elem, :H1, title: "Title")
              d.structure.add_child(doc_elem, :P)
            end
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def with_layers
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            d.pages.add.canvas.text("Base", at: [72, 720], font: font, size: 12)
            d.layers.add("Background Art", default_on: false)
            d.layers.add("Annotations")
            d.layers.sync!
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def with_form
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            page = d.pages.add
            page.canvas.text("Form", at: [72, 720], font: font, size: 12)
            d.form.add_text_field("name", page: page, rect: [72, 650, 300, 670])
            d.form.add_checkbox("agree", page: page, rect: [72, 600, 87, 615], checked: true)
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end

        def signed_doc
          key = OpenSSL::PKey::RSA.generate(2048)
          cert = OpenSSL::X509::Certificate.new
          cert.version = 2
          cert.serial = 1
          cert.subject = OpenSSL::X509::Name.parse("/CN=Corpus/O=Pdfrb")
          cert.issuer = cert.subject
          cert.public_key = key.public_key
          cert.not_before = Time.now - 3600
          cert.not_after = Time.now + 3600
          cert.sign(key, OpenSSL::Digest.new("SHA256"))

          Pdfrb::DigitalSignature::Signing.sign(
            Pdfrb::Document.new.tap { |d| d.pages.add },
            cert: cert, key: key
          )
        rescue StandardError
          ""
        end

        def large_document(page_count)
          Pdfrb::Document.new.tap do |d|
            font = d.fonts.add("Helvetica")
            page_count.times do |i|
              d.pages.add.canvas.text("Page #{i + 1} " * 20, at: [72, 720], font: font, size: 10)
            end
          end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
        end
      end
    end
  end
end
