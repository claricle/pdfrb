# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "semantic text-string decoding" do
  def write_and_reopen(doc)
    io = StringIO.new
    doc.write(io: io)
    Pdfrb::Document.new(io: StringIO.new(io.string.b))
  end

  it "decodes annotation /Contents after a round trip" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    doc.annotations.add_text_note(page, rect: [50, 700, 250, 750],
                                        contents: "メモ: review by Friday")

    reopened = write_and_reopen(doc)
    annots = reopened.annotations.each(reopened.pages.first).to_a
    expect(annots.length).to eq(1)
    expect(annots.first.contents).to eq("メモ: review by Friday")
  end

  it "decodes annotation /Contents from an encrypted round trip" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    doc.annotations.add_text_note(page, rect: [50, 700, 250, 750],
                                        contents: "極秘メモ")
    doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: 256)

    io = StringIO.new
    doc.write(io: io)
    reopened = Pdfrb::Document.new(io: StringIO.new(io.string.b),
                                   config: { "encryption.password" => "s3cret" })

    annots = reopened.annotations.each(reopened.pages.first).to_a
    expect(annots.first.contents).to eq("極秘メモ")
  end

  it "finds, lists, and reads form fields with non-ASCII names" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    doc.form.enable!
    doc.form.add_text_field("氏名", page: page, rect: [50, 700, 300, 720],
                                  value: "山田太郎")
    doc.form.add_text_field("email", page: page, rect: [50, 650, 300, 670])

    reopened = write_and_reopen(doc)

    expect(reopened.form.field_names).to contain_exactly("氏名", "email")
    expect(reopened.form.find("氏名")).not_to be_nil
    expect(reopened.form.get_value("氏名")).to eq("山田太郎")
    expect(reopened.form.get_value("email")).to be_nil
  end

  it "decodes non-string field values untouched" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    doc.form.enable!
    doc.form.add_checkbox("subscribe", page: page, rect: [50, 700, 70, 720],
                                       checked: true)

    reopened = write_and_reopen(doc)

    expect(reopened.form.get_value("subscribe")).to eq(:Yes)
  end
end
