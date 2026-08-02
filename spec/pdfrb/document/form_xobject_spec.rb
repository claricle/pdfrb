# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::FormXObject do
  let(:doc) { Pdfrb::Document.new }

  it "creates a Form XObject with a canvas" do
    form = doc.create_form_xobject(name: "Logo", bbox: [0, 0, 100, 50])
    font = doc.fonts.add("Helvetica")
    form.canvas.text("LOGO", at: [10, 10], font: font, size: 24)
    form.finalize!

    expect(form.stream[:Subtype]).to eq(:Form)
    expect(form.stream[:BBox]).to eq([0, 0, 100, 50])
    expect(form.stream.stream).to include("LOGO")
  end

  it "registers on a page" do
    form = doc.create_form_xobject(name: "Header")
    page = doc.pages.add
    form.register_on_page(page)

    xobjects = page.value[:Resources][:XObject]
    expect(xobjects[:Header]).not_to be_nil
  end

  it "round-trips through write + read" do
    form = doc.create_form_xobject(name: "Template", bbox: [0, 0, 200, 100])
    font = doc.fonts.add("Helvetica")
    form.canvas.text("Reusable", at: [10, 50], font: font, size: 12)
    form.finalize!

    page = doc.pages.add
    form.register_on_page(page)

    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    page = reloaded.pages[0]
    xobjects = begin
      page[:Resources][:XObject]
    rescue StandardError
      nil
    end
    if xobjects.nil?
      xobjects = begin
        reloaded.object(page[:Resources])[:XObject]
      rescue StandardError
        nil
      end
    end

    expect(xobjects).not_to be_nil
  end
end
