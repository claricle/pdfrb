# Pdfrb Usage Guide

A cookbook of common PDF tasks using pdfrb.

## Creating a PDF

```ruby
require "pdfrb"

doc = Pdfrb::Document.new
font = doc.fonts.add("Helvetica")
page = doc.pages.add
page.canvas.text("Hello, World!", at: [72, 720], font: font, size: 24)

doc.write("hello.pdf")
```

## Reading a PDF

```ruby
doc = Pdfrb.open("input.pdf")
puts "Pages: #{doc.pages.count}"
doc.pages.each do |page|
  text = Pdfrb::Task::ExtractText.call_single_page(page)
  puts text
end
```

## Drawing on a Canvas

```ruby
doc = Pdfrb::Document.new
page = doc.pages.add
font = doc.fonts.add("Helvetica")

page.canvas.tap do |c|
  c.text("Title", at: [72, 720], font: font, size: 18)
  c.rectangle(point: [72, 700], width: 200, height: 50)
  c.stroke
  c.line(from: [72, 600], to: [300, 600])
  c.stroke
end

doc.write("drawing.pdf")
```

## Embedding an ICC Profile

```ruby
icc_bytes = File.binread("sRGB.icc")
cs = doc.colors.embed_icc_profile(icc_bytes)
page = doc.pages.first
cs_name = doc.colors.register(page, cs)
# Use cs_name in content stream: "/CS1 cs 0.5 0.3 0.2 scn"
```

## Tagged PDF (Accessibility)

```ruby
doc.structure.enable!
doc.catalog.value[:Lang] = "en-US"

doc_elem = doc.structure.add_element(:Document)
doc.structure.add_child(doc_elem, :H1, title: "Introduction")
doc.structure.add_child(doc_elem, :P)
```

## Optional Content Groups (Layers)

```ruby
doc.layers.add("Background Art", default_on: false)
doc.layers.add("Annotations")
doc.layers.sync!
```

## Interactive Forms (AcroForm)

```ruby
page = doc.pages.add
doc.form.add_text_field("username", page: page, rect: [50, 700, 250, 720])
doc.form.add_checkbox("agree", page: page, rect: [50, 650, 65, 665], checked: true)
doc.form.add_combo("country", page: page, rect: [50, 600, 200, 620],
                    options: ["US", "UK", "JP"], value: "US")
```

## Digital Signatures

```ruby
cert = OpenSSL::X509::Certificate.new(File.read("cert.pem"))
key = OpenSSL::PKey::RSA.new(File.read("key.pem"))

signed = Pdfrb::DigitalSignature::Signing.sign(doc, cert: cert, key: key,
                                                reason: "Approval")
File.binwrite("signed.pdf", signed)

# Verify
results = Pdfrb::DigitalSignature::Verification.verify(signed, trusted_certs: [cert])
puts "Valid: #{results.first.valid?}"
```

## Semantic Comparison (Diff)

```ruby
left = File.binread("v1.pdf")
right = File.binread("v2.pdf")
report = Pdfrb::Compare.compare(left, right)

puts "Pages: #{report.page_count_delta}"
puts "Fonts added: #{report.font_diff[:added]}"
puts "Equivalent: #{report.equivalent?}"
```

## PDF/A Generation

```ruby
doc = Pdfrb::Document.new
doc.enable_pdf_a!(part: 2, conformance: "B") # sRGB OutputIntent + pdfaid XMP
font = doc.fonts.add("/path/to/font.ttf")    # PDF/A requires embedded fonts
doc.pages.add.canvas.text("Archived", at: [72, 720], font: font, size: 24)
doc.write("archival.pdf")

# Validate with veraPDF (brew install verapdf):
result = Pdfrb::Task::VeraPdfCrossCheck.call("archival.pdf", flavour: :a2b)
puts result.compliant? ? "PASS" : result.failures.map(&:message)
```

## Conformance Validation

```ruby
doc = Pdfrb.open("archival.pdf")

# PDF/A
result = Pdfrb::Conformance::PdfA.validate(doc, level: :a2b)
puts "PDF/A-2b: #{result.passed? ? 'PASS' : 'FAIL'}"
result.errors.each { |e| puts "  ERROR: #{e.message}" }

# PDF/UA
result = Pdfrb::Conformance::PdfUA.validate(doc)
puts "PDF/UA: #{result.passed? ? 'PASS' : 'FAIL'}"
```

## Linearization (Fast Web View)

```ruby
doc = Pdfrb.open("large.pdf")
io = StringIO.new
Pdfrb::Linearization::Writer.new(doc).write(io)
File.binwrite("linearized.pdf", io.string)
```

## Encryption

```ruby
doc = Pdfrb::Document.new
doc.pages.add
doc.metadata[:Title] = "Confidential"
doc.encrypt!(user_password: "secret", owner_password: "owner", bits: 128)
doc.write("encrypted.pdf")

# Opening an encrypted document — strings and streams decrypt on
# read; a wrong password raises Pdfrb::EncryptionError:
doc = Pdfrb.open("encrypted.pdf",
                 config: { "encryption.password" => "secret" })
doc.metadata[:Title] # => "Confidential"

# Removing encryption from a parsed document:
doc.decrypt!
doc.write("decrypted.pdf")
```

## Bookmarks (Outlines)

```ruby
doc = Pdfrb::Document.new
page = doc.pages.add
font = doc.fonts.add("Helvetica")
page.canvas.text("Intro", at: [72, 720], font: font, size: 12)

chapter = doc.outline.add("Chapter 1", dest: :xyz)
chapter.add_child(Pdfrb::Document::OutlineEntry.new(title: "1.1", dest: :xyz))
doc.outline.add("Chapter 2", dest: :xyz)
doc.outline.build!
doc.write("bookmarked.pdf")

# Reading an outline back (depth-first, parents before children):
doc = Pdfrb.open("bookmarked.pdf")
doc.outline.each do |item|
  puts item.title   # "Chapter 1", "1.1", "Chapter 2"
end
```

## Merging PDFs

```ruby
target = Pdfrb.open("base.pdf")
source = Pdfrb.open("appendix.pdf")
Pdfrb::Task::Merge.call(target, source)
target.write("merged.pdf")
```

## Extracting Images

```ruby
doc = Pdfrb.open("input.pdf")
images = Pdfrb::Task::ExtractImages.call(doc)
images.each_with_index do |img, i|
  File.binwrite("image_#{i}.#{img[:format]}", img[:data])
end
```

## CLI

```sh
pdfrb info input.pdf
pdfrb extract-text input.pdf
pdfrb merge a.pdf b.pdf -o merged.pdf
pdfrb diff v1.pdf v2.pdf
pdfrb encrypt input.pdf -o encrypted.pdf
pdfrb optimize input.pdf -o optimized.pdf
```
