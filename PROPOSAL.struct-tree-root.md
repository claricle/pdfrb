# PROPOSAL: StructTreeRoot for tagged PDF (PDF/UA)

## Summary

Add `Document#structure` facade for building PDF structure trees
(`/StructTreeRoot`), enabling tagged PDF output for accessibility
(PDF/UA, WCAG 2.1, Section 508 compliance).

## Motivation

pdfrb 0.3.0 already has Canvas tagged-content support (`tagged`,
`artifact`, `marked_content`), but lacks the `/StructTreeRoot` assembly
that ties tagged content sequences into a navigable structure tree.
Without StructTreeRoot, screen readers cannot navigate the document.

The `idml` gem needs tagged PDF output for:
- Government documents (Section 508 compliance)
- Academic publishing (WCAG 2.1 AA)
- Accessible PDF/A (PDF/A-1a, PDF/A-2a)

## Proposed API

```ruby
# Build structure tree
doc.structure.add_element(:H1, text: "Chapter 1", page: 0, mcid: 0)
doc.structure.add_element(:P, text: "Body text...", page: 0, mcid: 1)
doc.structure.add_element(:Figure, alt: "Diagram", page: 1, mcid: 2)
doc.structure.add_element(:TR, children: [
  doc.structure.element(:TH, text: "Name"),
  doc.structure.element(:TH, text: "Value"),
])

# Mark content in the Canvas
page.canvas.tagged(:H1, mcid: 0) { canvas.text("Chapter 1", ...) }
page.canvas.tagged(:P, mcid: 1) { canvas.text("Body text...", ...) }

# Build and attach to Catalog
doc.structure.build!
```

## PDF structure

```
/StructTreeRoot
  /Type /StructTreeRoot
  /K [ struct_elem_0 struct_elem_1 ... ]
  /ParentTree << /Nums [ 0 [elem_ref] 1 [elem_ref] ... ] >>
  /ParentTreeNextKey N

/StructElem (each)
  /Type /StructElem
  /S /H1               (structure type: H1, P, Figure, TR, TH, TD, ...)
  /P struct_tree_root  (parent)
  /K mcid_or_ref       (content reference)
  /Pg page_ref         (page containing the content)
  /Alt (alt text)      (for figures)
```

## Implementation outline

```ruby
class Pdfrb::Document
  class Structure
    attr_reader :document, :elements

    def initialize(document)
      @document = document
      @elements = []
      @next_mcid = 0
    end

    def add_element(type, text: nil, alt: nil, page:, mcid:, **opts)
      elem = StructElement.new(type, text:, alt:, page:, mcid:, **opts)
      @elements << elem
      elem
    end

    def next_mcid
      id = @next_mcid
      @next_mcid += 1
      id
    end

    # Build /StructTreeRoot and attach to Catalog.
    def build!
      return if @elements.empty?

      root_id = allocate_struct_tree_root
      @elements.each { |e| e.build_object(document, root_id) }
      build_parent_tree(root_id)
      document.catalog[:StructTreeRoot] = Pdfrb::Model::Reference.new(root_id)
      document.catalog[:MarkInfo] = { Type: :MarkInfo, Marked: true }
    end
  end
end
```

## Priority

Medium — the Canvas already supports marked content (`BMC`/`EMC`), so
this is the missing piece for full tagged PDF. Not blocking for basic
rendering but essential for accessibility compliance.
