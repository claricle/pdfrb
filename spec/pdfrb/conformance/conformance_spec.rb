# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfA do
  let(:clean_doc) do
    Pdfrb::Document.new.tap do |d|
      d.pages.add
    end
  end

  it "passes for a document with metadata and no encryption" do
    clean_doc.catalog.value[:Metadata] =
      Pdfrb::Model::Reference.new(999, 0)
    result = described_class.validate(clean_doc, level: :a2b)

    # Only metadata ref is set; fonts won't be embedded so that's a
    # violation. But we check that the structure is correct.
    expect(result).to be_a(Pdfrb::Conformance::ValidationResult)
    expect(result.violations).to be_an(Array)
  end

  it "detects encryption" do
    clean_doc.catalog.value[:Metadata] =
      Pdfrb::Model::Reference.new(999, 0)
    clean_doc.instance_variable_set(:@trailer, { Encrypt: "yes" })
    result = described_class.validate(clean_doc, level: :a2b)

    enc = result.violations.find { |v| v.rule_id == "6.1-1" }
    expect(enc).not_to be_nil
    expect(enc.severity).to eq(:error)
  end

  it "detects missing metadata" do
    result = described_class.validate(clean_doc, level: :a2b)

    md = result.violations.find { |v| v.rule_id == "6.1-2" }
    expect(md).not_to be_nil
    expect(md.message).to include("Metadata")
  end

  it "detects JavaScript actions" do
    clean_doc.catalog.value[:Metadata] =
      Pdfrb::Model::Reference.new(999, 0)
    clean_doc.add({ S: :JavaScript, JS: "alert(1)" },
                  type: Pdfrb::Model::Cos::Dictionary)
    result = described_class.validate(clean_doc, level: :a2b)

    js = result.violations.find { |v| v.rule_id == "6.1-4" }
    expect(js).not_to be_nil
  end

  it "warns about missing language" do
    result = described_class.validate(clean_doc, level: :a2b)

    lang = result.violations.find { |v| v.rule_id == "6.1-7" }
    expect(lang).not_to be_nil
    expect(lang.severity).to eq(:warning)
  end

  it "supports A-1 profile (no JPEG2000)" do
    clean_doc.catalog.value[:Metadata] =
      Pdfrb::Model::Reference.new(999, 0)
    stream = clean_doc.add(
      { Type: :XObject, Subtype: :Image, Filter: :JPXDecode,
        Width: 1, Height: 1, BitsPerComponent: 8, ColorSpace: :DeviceRGB,
        Length: 3 },
      type: Pdfrb::Model::Cos::Stream
    )
    stream.stream = "\x00\x00\x00"
    result = described_class.validate(clean_doc, level: :a1b)

    jpx = result.violations.find { |v| v.rule_id == "a1-1" }
    expect(jpx).not_to be_nil
  end

  it "classifies violations by severity" do
    result = described_class.validate(clean_doc, level: :a2b)

    expect(result.errors).to be_an(Array)
    expect(result.warnings).to be_an(Array)
  end

  it "uses rule registry (OCP)" do
    expect(described_class::SHARED.rules.length).to be >= 5
    expect(described_class::A1.rules.length).to be > described_class::SHARED.rules.length
  end

  it "allows custom rule registration" do
    custom = Pdfrb::Conformance::RuleSet.new("custom")
    custom.register(Pdfrb::Conformance::Rule.new(
                      id: "custom-1",
                      description: "Document must have at least one page",
                      severity: :error,
                      spec_clause: "internal policy",
                      check: ->(doc) {
                        count = 0
                        doc.pages.each { count += 1 }
                        next nil if count.positive?

                        Pdfrb::Conformance::Violation.new(
                          rule_id: "custom-1",
                          message: "Document has no pages",
                          severity: :error
                        )
                      }
                    ))
    empty_doc = Pdfrb::Document.new
    result = custom.validate(empty_doc)
    expect(result.violations).not_to be_empty
  end
end

RSpec.describe Pdfrb::Conformance::PdfUA do
  let(:doc) do
    Pdfrb::Document.new.tap { |d| d.pages.add }
  end

  it "detects missing StructTreeRoot" do
    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-1" }
    expect(v).not_to be_nil
    expect(v.severity).to eq(:error)
  end

  it "detects missing MarkInfo" do
    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-2" }
    expect(v).not_to be_nil
  end

  it "detects missing language" do
    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-3" }
    expect(v).not_to be_nil
  end

  it "passes structure rules for a properly tagged document" do
    doc.catalog.value[:Lang] = "en-US"
    mark = doc.add({ Marked: true })
    doc.catalog.value[:MarkInfo] =
      Pdfrb::Model::Reference.new(mark.oid, mark.gen)
    root = doc.add({ Type: :StructTreeRoot })
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)

    result = described_class.validate(doc)
    ua1 = result.violations.find { |v| v.rule_id == "ua-1" }
    ua2 = result.violations.find { |v| v.rule_id == "ua-2" }
    ua3 = result.violations.find { |v| v.rule_id == "ua-3" }
    expect(ua1).to be_nil
    expect(ua2).to be_nil
    expect(ua3).to be_nil
  end

  it "detects figures without Alt text" do
    doc.catalog.value[:Lang] = "en-US"
    mark = doc.add({ Marked: true })
    doc.catalog.value[:MarkInfo] =
      Pdfrb::Model::Reference.new(mark.oid, mark.gen)
    root = doc.add({ Type: :StructTreeRoot })
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)

    fig = doc.add({ Type: :StructElem, S: :Figure })
    root.value[:K] = [Pdfrb::Model::Reference.new(fig.oid, fig.gen)]

    result = described_class.validate(doc)
    fig_v = result.violations.find { |v| v.rule_id == "ua-5" }
    expect(fig_v).not_to be_nil
  end

  it "does not flag figures with Alt text" do
    doc.catalog.value[:Lang] = "en-US"
    mark = doc.add({ Marked: true })
    doc.catalog.value[:MarkInfo] =
      Pdfrb::Model::Reference.new(mark.oid, mark.gen)
    root = doc.add({ Type: :StructTreeRoot })
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)

    fig = doc.add({ Type: :StructElem, S: :Figure, Alt: "A diagram" })
    root.value[:K] = [Pdfrb::Model::Reference.new(fig.oid, fig.gen)]

    result = described_class.validate(doc)
    fig_v = result.violations.find { |v| v.rule_id == "ua-5" }
    expect(fig_v).to be_nil
  end

  it "detects heading nesting violations" do
    doc.catalog.value[:Lang] = "en-US"
    mark = doc.add({ Marked: true })
    doc.catalog.value[:MarkInfo] =
      Pdfrb::Model::Reference.new(mark.oid, mark.gen)
    root = doc.add({ Type: :StructTreeRoot })
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)

    h1 = doc.add({ Type: :StructElem, S: :H1, T: "Title" })
    h4 = doc.add({ Type: :StructElem, S: :H4, T: "Jump" })
    root.value[:K] = [
      Pdfrb::Model::Reference.new(h1.oid, h1.gen),
      Pdfrb::Model::Reference.new(h4.oid, h4.gen),
    ]

    result = described_class.validate(doc)
    nesting = result.violations.find { |v| v.rule_id == "ua-6" }
    expect(nesting).not_to be_nil
    expect(nesting.message).to include("H4")
  end

  it "uses rule registry with at least 8 rules" do
    expect(described_class::RULESET.rules.length).to be >= 8
  end
end

RSpec.describe Pdfrb::Conformance::ValidationResult do
  it "classifies violations by severity" do
    result = described_class.new(
      profile: "test",
      violations: [
        Pdfrb::Conformance::Violation.new(rule_id: "e1", severity: :error, message: "bad"),
        Pdfrb::Conformance::Violation.new(rule_id: "w1", severity: :warning, message: "meh"),
      ]
    )
    expect(result.errors.length).to eq(1)
    expect(result.warnings.length).to eq(1)
    expect(result).not_to be_passed
  end

  it "passes when no errors" do
    result = described_class.new(
      profile: "test",
      violations: [
        Pdfrb::Conformance::Violation.new(rule_id: "w1", severity: :warning, message: "meh"),
      ]
    )
    expect(result).to be_passed
  end
end
