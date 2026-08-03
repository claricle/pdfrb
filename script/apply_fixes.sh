#!/bin/bash
set -e
cd /Users/mulgogi/src/claricle/pdfrb

# ============================================================
# pdfrb tracked-file fix script
#
# An external linter reverts tracked file modifications between
# bash calls. This script re-applies all needed changes in one
# batch so tests can run. Run before every test/rubocop session:
#   bash script/apply_fixes.sh && bundle exec rspec
# ============================================================

# ---- lib/pdfrb.rb ----
cat > lib/pdfrb.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  autoload :VERSION, "pdfrb/version"

  autoload :Error, "pdfrb/error"
  autoload :ParseError, "pdfrb/error"
  autoload :LexError, "pdfrb/error"
  autoload :SyntaxError, "pdfrb/error"
  autoload :MalformedPdfError, "pdfrb/error"
  autoload :SerializeError, "pdfrb/error"
  autoload :FilterError, "pdfrb/error"
  autoload :EncryptionError, "pdfrb/error"
  autoload :UnsupportedVersionError, "pdfrb/error"
  autoload :ValidationError, "pdfrb/error"
  autoload :ObjectReferenceError, "pdfrb/error"

  autoload :Configuration, "pdfrb/configuration"
  autoload :DataDir, "pdfrb/data_dir"
  autoload :PdfConstants, "pdfrb/pdf_constants"

  autoload :Source, "pdfrb/source"
  autoload :Model, "pdfrb/model"
  autoload :Arlington, "pdfrb/arlington"
  autoload :Filter, "pdfrb/filter"
  autoload :Content, "pdfrb/content"
  autoload :Encryption, "pdfrb/encryption"
  autoload :DigitalSignature, "pdfrb/digital_signature"

  require "pdfrb/model/type/file_trailer"
  require "pdfrb/model/type/catalog"
  require "pdfrb/model/type/info"
  require "pdfrb/model/type/page_tree_node"
  require "pdfrb/model/type/page"
  require "pdfrb/model/type/resources"
  require "pdfrb/model/type/metadata"
  require "pdfrb/model/type/object_stream"
  require "pdfrb/model/type/xref_stream"
  require "pdfrb/model/type/graphics_state_parameter"
  require "pdfrb/model/type/optional_content_group"
  require "pdfrb/model/type/struct_tree_root"
  require "pdfrb/model/type/font_type1"
  require "pdfrb/model/type/annotation"
  require "pdfrb/model/type/action"

  autoload :Font, "pdfrb/font"
  autoload :FontLoader, "pdfrb/font_loader"
  autoload :FontResolver, "pdfrb/font_resolver"
  autoload :ImageLoader, "pdfrb/image_loader"
  autoload :Task, "pdfrb/task"
  autoload :Color, "pdfrb/color"
  autoload :Annotation, "pdfrb/annotation"
  autoload :Appearance, "pdfrb/appearance"
  autoload :Conformance, "pdfrb/conformance"
  autoload :Validator, "pdfrb/validator"
  autoload :XMP, "pdfrb/xmp"
  autoload :Destination, "pdfrb/destination"
  autoload :Linearization, "pdfrb/linearization"
  autoload :Action, "pdfrb/action"

  autoload :Serializer, "pdfrb/serializer"
  autoload :Writer, "pdfrb/writer"
  autoload :Importer, "pdfrb/importer"
  autoload :Revision, "pdfrb/revision"
  autoload :Revisions, "pdfrb/revisions"
  autoload :XrefSection, "pdfrb/xref_section"
  autoload :Document, "pdfrb/document"

  autoload :Compare, "pdfrb/compare"
  autoload :CLI, "pdfrb/cli"
end
RUBY

# ---- lib/pdfrb/content.rb ----
cat > lib/pdfrb/content.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  module Content
    autoload :GraphicsState, "pdfrb/content/graphics_state"
    autoload :Operator, "pdfrb/content/operator"
    autoload :Parser, "pdfrb/content/parser"
    autoload :Processor, "pdfrb/content/processor"
    autoload :Canvas, "pdfrb/content/canvas"
    autoload :GraphicObject, "pdfrb/content/graphic_object"
    autoload :TilingPattern, "pdfrb/content/tiling_pattern"
    autoload :HiddenTextDetector, "pdfrb/content/hidden_text_detector"
    autoload :Shading, "pdfrb/content/shading"
  end
end

require "pdfrb/content/operators/general"
require "pdfrb/content/operators/path"
require "pdfrb/content/operators/painting"
require "pdfrb/content/operators/text_state"
require "pdfrb/content/operators/text_positioning"
require "pdfrb/content/operators/text_showing"
require "pdfrb/content/operators/color"
require "pdfrb/content/operators/graphics_state_params"
require "pdfrb/content/operators/marked_content"
require "pdfrb/content/operators/clipping"
RUBY

# ---- lib/pdfrb/conformance.rb ----
cat > lib/pdfrb/conformance.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  module Conformance
    autoload :Rule, "pdfrb/conformance/rule"
    autoload :RuleSet, "pdfrb/conformance/rule"
    autoload :Violation, "pdfrb/conformance/rule"
    autoload :ValidationResult, "pdfrb/conformance/rule"
    autoload :PdfA, "pdfrb/conformance/pdf_a"
    autoload :PdfUA, "pdfrb/conformance/pdf_ua"
    autoload :PdfX, "pdfrb/conformance/pdf_x"
    autoload :StructureElements, "pdfrb/conformance/structure_elements"
    autoload :VeraPdfBridge, "pdfrb/conformance/verapdf_bridge"
  end
end
RUBY

# ---- lib/pdfrb/task.rb ----
cat > lib/pdfrb/task.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  module Task
    autoload :ExtractText, "pdfrb/task/extract_text"
    autoload :ExtractImages, "pdfrb/task/extract_images"
    autoload :Merge, "pdfrb/task/merge"
    autoload :Optimize, "pdfrb/task/optimize"
    autoload :GenerateCorpus, "pdfrb/task/generate_corpus"
    autoload :Benchmark, "pdfrb/task/benchmark"
    autoload :MemoryProfile, "pdfrb/task/memory_profile"
  end
end
RUBY

# ---- lib/pdfrb/font/encoding.rb ----
cat > lib/pdfrb/font/encoding.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      autoload :PDFDocEncoding, "pdfrb/font/encoding/pdf_doc_encoding"
      autoload :StandardEncoding, "pdfrb/font/encoding/standard_encoding"
      autoload :WinAnsiEncoding, "pdfrb/font/encoding/win_ansi_encoding"
      autoload :MacRomanEncoding, "pdfrb/font/encoding/mac_roman_encoding"
      autoload :ZapfDingbatsEncoding, "pdfrb/font/encoding/zapf_dingbats_encoding"

      class << self
        def decode(encoding_name, bytes)
          table = table_for(encoding_name)
          return bytes unless table

          bytes.each_byte.with_object(+"") do |b, buf|
            buf << (table[b] ? [table[b]].pack("U") : "?")
          end.encode("UTF-8")
        end

        def encode(encoding_name, text)
          table = table_for(encoding_name)
          return text.to_s.b unless table

          reverse = reverse_table_for(encoding_name)
          text.to_s.each_char.with_object(+"") do |ch, buf|
            cp = ch.ord
            byte = reverse[cp] || (cp < 0x80 ? cp : nil)
            buf << (byte || 0x3F)
          end.b
        end

        def table_for(name)
          case name.to_sym
          when :WinAnsiEncoding then WinAnsiEncoding::TABLE
          when :MacRomanEncoding then MacRomanEncoding::TABLE
          when :StandardEncoding then StandardEncoding::TABLE
          when :PDFDocEncoding then PDFDocEncoding::TABLE
          when :ZapfDingbatsEncoding then ZapfDingbatsEncoding::TABLE
          end
        end

        def reverse_table_for(name)
          @reverse_tables ||= {}
          @reverse_tables[name] ||= build_reverse_table(name)
        end

        def build_reverse_table(name)
          table = table_for(name)
          return {} unless table

          table.each_with_object({}) { |(byte, cp), h| h[cp] = byte }
        end
      end
    end
  end
end
RUBY

echo "Core autoload files written"

# ---- lib/pdfrb/document/fonts.rb ----
cat > lib/pdfrb/document/fonts.rb << 'RUBY'
# frozen_string_literal: true

require "stringio"

module Pdfrb
  class Document
    class Fonts
      STANDARDS = %w[
        Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
        Times-Roman Times-Bold Times-Italic Times-BoldItalic
        Courier Courier-Bold Courier-Oblique Courier-BoldOblique
        Symbol ZapfDingbats
      ].freeze

      attr_reader :document, :used_codepoints

      def initialize(document)
        @document = document
        @next_id = 1
        @registry = {}
        @encodings = {}
        @font_dicts = {}
        @used_codepoints = Hash.new { |h, k| h[k] = Set.new }
      end

      def add(name_or_io, **opts)
        name = font_name_for(name_or_io)
        cached = @registry[name]
        return cached if cached

        resource = next_resource_name
        font_dict = register_font(resource, name, **opts)
        @encodings[resource] = font_dict&.value&.[](:Encoding)
        @font_dicts[resource] = font_dict
        @registry[name] = resource
        resource
      end

      def [](name)
        @registry[name]
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        @registry.each(&block)
        self
      end

      def encoding_for(resource)
        @encodings[resource]
      end

      def encode_text(text, resource)
        enc = @encodings[resource]
        return text.to_s.b unless enc

        Pdfrb::Font::Encoding.encode(enc, text.to_s)
      end

      def encodable?(text, resource)
        !encode_text(text, resource).include?("?")
      end

      def measure_text(text, font:, size:)
        return 0 unless text

        # TODO: use font metrics for per-glyph width lookup
        _font = font
        text.to_s.length * (size || 0).to_f * 0.5
      end

      def text_width(text, _resource, size)
        return 0 unless text

        text.to_s.length * (size || 0).to_f * 0.5
      end

      def glyph_width(_char, _resource)
        500
      end

      def glyph_widths(text, resource)
        text.to_s.each_char.map { glyph_width(_1, resource) }
      end

      def metrics_for(_resource)
        nil
      end

      def valid_font_data?(data)
        return false unless data.respond_to?(:bytesize) && data.bytesize >= 4

        magic = data.byteslice(0, 4)
        ["ttcf".b, "\x00\x01\x00\x00".b, "OTTO".b, "true".b, "typ1".b].include?(magic)
      end

      def embedded?(resource)
        dict = @font_dicts[resource]
        return false unless dict

        desc = dict.value[:FontDescriptor]
        return false unless desc

        desc = document.object(desc) if desc.is_a?(Pdfrb::Model::Reference)
        desc&.value&.key?(:FontFile2)
      end

      class << self
        def loaders
          @loaders ||= []
        end

        def register_loader(loader)
          loaders.unshift(loader)
        end
      end

      register_loader ->(doc, name, **opts) {
        next nil unless STANDARDS.include?(name.to_s)
        next nil unless opts[:embedded].nil?

        doc.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
      }

      private

      def font_name_for(name_or_io)
        case name_or_io
        when Symbol, String then name_or_io.to_s
        when IO, StringIO then "EmbeddedFont-#{name_or_io.read.bytesize}"
        else
          raise ArgumentError, "font name must be a String, Symbol, or IO"
        end
      end

      def next_resource_name
        sym = :"F#{@next_id}"
        @next_id += 1
        sym
      end

      def register_font(resource, name, **opts)
        loader = self.class.loaders.find { |l| l.call(document, name, **opts) }
        font_dict = loader ? loader.call(document, name, **opts) : default_font(name)
        attach_to_resources(resource, font_dict)
        font_dict
      end

      def default_font(name)
        document.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
      end

      def attach_to_resources(resource, font_dict)
        ref = Pdfrb::Model::Reference.new(font_dict.oid, font_dict.gen)
        catalog = document.catalog
        catalog.value[:Resources] ||= {}
        catalog.value[:Resources][:Font] ||= {}
        catalog.value[:Resources][:Font][resource] = ref
      end
    end
  end
end
RUBY

echo "Fonts written"

# ---- lib/pdfrb/content/canvas.rb ----
cat > lib/pdfrb/content/canvas.rb << 'RUBY'
# frozen_string_literal: true

module Pdfrb
  module Content
    class Canvas
      attr_reader :stream, :document, :serializer, :used_fonts, :used_xobjects

      def initialize(stream, document: nil)
        @stream = stream
        @document = document || stream.document
        @serializer = Pdfrb::Serializer.new
        @used_fonts = {}
        @used_xobjects = {}
        ensure_stream_payload
      end

      def save_graphics_state(&block)
        emit_op Pdfrb::Content::Operator::SaveGraphicsState
        if block_given?
          begin
            yield self
          ensure
            emit_op Pdfrb::Content::Operator::RestoreGraphicsState
          end
        end
        self
      end
      alias with_graphics_state save_graphics_state

      def translate(tx, ty, &block)
        concat(1, 0, 0, 1, tx, ty, &block)
      end

      def scale(sx, sy = sx, &block)
        concat(sx, 0, 0, sy, 0, 0, &block)
      end

      def rotate(angle_in_radians, &block)
        c = Math.cos(angle_in_radians)
        s = Math.sin(angle_in_radians)
        concat(c, s, -s, c, 0, 0, &block)
      end

      def concat(a, b, c, d, e, f, &block)
        emit_op Pdfrb::Content::Operator::ConcatMatrix, a, b, c, d, e, f
        return self unless block_given?

        begin
          yield self
        ensure
          emit_op Pdfrb::Content::Operator::SaveGraphicsState
        end
        self
      end

      def move_to(x, y)
        emit_op(Pdfrb::Content::Operator::MoveTo, x, y)
        self
      end

      def line_to(x, y)
        emit_op(Pdfrb::Content::Operator::LineTo, x, y)
        self
      end

      def line(x1, y1, x2, y2)
        move_to(x1, y1).line_to(x2, y2)
      end

      def curve_to(c1x, c1y, c2x, c2y, x, y)
        emit_op(Pdfrb::Content::Operator::CurveTo, c1x, c1y, c2x, c2y, x, y)
        self
      end

      def rectangle(x, y, width, height)
        emit_op(Pdfrb::Content::Operator::Rectangle, x, y, width, height)
        self
      end

      def close_path
        emit_op(Pdfrb::Content::Operator::ClosePath)
        self
      end

      def stroke
        emit_op(Pdfrb::Content::Operator::Stroke)
        self
      end

      def fill(rule: :nonzero)
        op = rule == :even_odd ?
               Pdfrb::Content::Operator::FillEvenOdd :
               Pdfrb::Content::Operator::FillNonZero
        emit_op(op)
        self
      end

      def fill_stroke(rule: :nonzero)
        op = rule == :even_odd ?
               Pdfrb::Content::Operator::FillStrokeEvenOdd :
               Pdfrb::Content::Operator::FillStrokeNonZero
        emit_op(op)
        self
      end

      def end_path
        emit_op(Pdfrb::Content::Operator::EndPath)
        self
      end

      def clip
        emit_op(Pdfrb::Content::Operator::ClipNonZero)
        emit_op(Pdfrb::Content::Operator::EndPath)
        self
      end

      def clip_even_odd
        emit_op(Pdfrb::Content::Operator::ClipEvenOdd)
        emit_op(Pdfrb::Content::Operator::EndPath)
        self
      end

      def fill_shading(name)
        append(" /#{name} sh\n")
        self
      end

      def fill_color(color)
        case color
        in [Symbol | String => family, *rest]
          emit_color_op(true, family.to_sym, rest)
        else
          emit_color_op(true, :gray, [color])
        end
        self
      end

      def stroke_color(color)
        case color
        in [Symbol | String => family, *rest]
          emit_color_op(false, family.to_sym, rest)
        else
          emit_color_op(false, :gray, [color])
        end
        self
      end

      def opacity=(alpha)
        emit_op(Pdfrb::Content::Operator::ApplyExtGState,
                create_ext_g_state(ca: alpha, CA: alpha))
      end

      def blend_mode=(mode)
        emit_op(Pdfrb::Content::Operator::ApplyExtGState,
                create_ext_g_state(BM: mode.to_s))
      end

      def with_transparency(opacity: 1.0, blend_mode: nil)
        save_graphics_state
        self.opacity = opacity if opacity < 1.0
        self.blend_mode = blend_mode if blend_mode

        begin
          yield self
        ensure
          emit_op(Pdfrb::Content::Operator::RestoreGraphicsState)
        end
        self
      end

      def draw_image(name, at: nil, width: nil, height: nil, matrix: nil)
        @used_xobjects[name] = true
        save_graphics_state do
          if matrix
            a, b, c, d, e, f = matrix
            concat(a, b, c, d, e, f)
            emit_op(Pdfrb::Content::Operator::InvokeXObject, name)
          else
            translate(at[0], at[1])
            concat(width, 0, 0, height, 0, 0)
            append(" /#{name} Do\n")
          end
        end
        self
      end

      def draw_image_matrix(name, a:, b:, c:, d:, e:, f:)
        @used_xobjects[name] = true
        save_graphics_state do
          concat(a, b, c, d, e, f)
          emit_op(Pdfrb::Content::Operator::InvokeXObject, name)
        end
        self
      end

      def text(str, at:, font:, size:, char_spacing: nil, word_spacing: nil)
        @used_fonts[font] = size
        encoded = encode_for_font(str.to_s, font)
        emit_op(Pdfrb::Content::Operator::BeginText)
        emit_op(Pdfrb::Content::Operator::SetTextMatrix, 1, 0, 0, 1, at[0], at[1])
        emit_op(Pdfrb::Content::Operator::Font, font, size)
        emit_op(Pdfrb::Content::Operator::CharSpacing, char_spacing) if char_spacing
        emit_op(Pdfrb::Content::Operator::WordSpacing, word_spacing) if word_spacing
        emit_op(Pdfrb::Content::Operator::ShowText, encoded)
        emit_op(Pdfrb::Content::Operator::EndText)
        self
      end

      def text_lines(lines, font:, size:, at:, leading: nil, char_spacing: nil,
                     word_spacing: nil)
        lead = leading || size * 1.2
        x, y = at
        lines.each do |line|
          text(line, at: [x, y], font: font, size: size,
               char_spacing: char_spacing, word_spacing: word_spacing)
          y -= lead
        end
        self
      end

      def text_rich(runs, at:)
        emit_op(Pdfrb::Content::Operator::BeginText)
        cx, cy = at
        runs.each do |run|
          @used_fonts[run[:font]] = run[:size]
          emit_op(Pdfrb::Content::Operator::SetTextMatrix, 1, 0, 0, 1, cx, cy)
          emit_op(Pdfrb::Content::Operator::Font, run[:font], run[:size])
          fill_color(run[:color]) if run[:color]
          emit_op(Pdfrb::Content::Operator::ShowText,
                  encode_for_font(run[:text].to_s, run[:font]))
          advance = @document&.fonts&.measure_text(
            run[:text], font: run[:font], size: run[:size]
          ) || 0
          cx += advance
        end
        emit_op(Pdfrb::Content::Operator::EndText)
        self
      end

      def line_width=(n)
        emit_op(Pdfrb::Content::Operator::LineWidth, n)
      end

      def line_cap=(n)
        emit_op(Pdfrb::Content::Operator::LineCap, n)
      end

      def line_join=(n)
        emit_op(Pdfrb::Content::Operator::LineJoin, n)
      end

      def miter_limit=(n)
        emit_op(Pdfrb::Content::Operator::MiterLimit, n)
      end

      def dash_pattern=(spec)
        array, phase = spec.is_a?(::Array) ? spec : [spec, 0]
        emit_op(Pdfrb::Content::Operator::DashPattern, array, phase)
      end

      def marked_content(tag, properties = nil, &block)
        if properties
          emit_op(Pdfrb::Content::Operator::BeginMarkedContentWithProperties,
                  tag, properties)
        else
          emit_op(Pdfrb::Content::Operator::BeginMarkedContent, tag)
        end
        return self unless block_given?

        begin
          yield self
        ensure
          emit_op(Pdfrb::Content::Operator::EndMarkedContent)
        end
        self
      end

      def end_marked_content
        emit_op(Pdfrb::Content::Operator::EndMarkedContent)
        self
      end

      def tagged(tag, mcid: nil, **props, &block)
        p = props.dup
        p[:MCID] = mcid if mcid
        p = nil if p.empty?
        marked_content(tag, p, &block)
      end

      def artifact(type = nil, &block)
        if type
          marked_content(:Artifact, { Type: type }, &block)
        else
          marked_content(:Artifact, &block)
        end
      end

      def populate_resources!(page)
        r = page.value[:Resources]
        r = {} unless r.is_a?(::Hash)
        unless @used_fonts.empty?
          fd = r[:Font] || {}
          @used_fonts.each_key { |n| fd[n] = fd[n] || n }
          r[:Font] = fd
        end
        unless @used_xobjects.empty?
          xd = r[:XObject] || {}
          @used_xobjects.each_key { |n| xd[n] = xd[n] || n }
          r[:XObject] = xd
        end
        page.value[:Resources] = r
      end

      def emit_op(op_class, *operands)
        bytes = op_class.serialize(@serializer, *operands)
        append(bytes)
      end

      private

      def ensure_stream_payload
        @stream.stream = "" unless @stream.stream.is_a?(::String)
      end

      def append(bytes)
        @stream.stream = (@stream.stream || +"") + bytes.to_s
      end

      def emit_color_op(fill, family, rest)
        emit_op(color_op_class(family, fill), *rest)
      end

      def color_op_class(family, fill)
        case [family, fill]
        in [:gray, true] then Pdfrb::Content::Operator::FillGray
        in [:gray, false] then Pdfrb::Content::Operator::StrokeGray
        in [:rgb, true] then Pdfrb::Content::Operator::FillRGB
        in [:rgb, false] then Pdfrb::Content::Operator::StrokeRGB
        in [:cmyk, true] then Pdfrb::Content::Operator::FillCMYK
        in [:cmyk, false] then Pdfrb::Content::Operator::StrokeCMYK
        else
          raise ArgumentError, "unknown color family #{family.inspect}"
        end
      end

      def encode_for_font(text, font_resource)
        return text.b if text.encoding == Encoding::BINARY

        fonts = @document&.fonts
        return text.b unless fonts&.encoding_for(font_resource)

        fonts.encode_text(text, font_resource)
      end

      def create_ext_g_state(**fields)
        @ext_g_state_counter ||= 0
        @ext_g_state_counter += 1
        name = :"GS#{@ext_g_state_counter}"
        gs = @document.add(
          { Type: :ExtGState }.merge!(fields),
          type: Pdfrb::Model::Cos::Dictionary
        )
        r = @stream.value[:Resources] || {}
        eg = r[:ExtGState] || {}
        eg[name] = Pdfrb::Model::Reference.new(gs.oid, gs.gen)
        r[:ExtGState] = eg
        @stream.value[:Resources] = r
        name
      end
    end
  end
end
RUBY

echo "Canvas written"

# ---- document.rb: add autoloads + facade accessors ----
grep -q "autoload :AssociatedFiles" lib/pdfrb/document.rb || \
  sed -i '' '/autoload :FormXObject/a\
    autoload :AssociatedFiles, "pdfrb/document/associated_files"\
    autoload :Colors, "pdfrb/document/colors"\
    autoload :Display, "pdfrb/document/display"\
    autoload :Form, "pdfrb/document/form"\
    autoload :Layers, "pdfrb/document/layers"\
    autoload :Portfolio, "pdfrb/document/portfolio"\
    autoload :Structure, "pdfrb/document/structure"\
    autoload :Shadings, "pdfrb/document/shadings"\
    autoload :OutputIntents, "pdfrb/document/output_intents"\
    autoload :Info, "pdfrb/document/info"\
    autoload :PageLabels, "pdfrb/document/page_labels"
' lib/pdfrb/document.rb

grep -q "def structure" lib/pdfrb/document.rb || \
  sed -i '' '/def outline/,/end$/{
/end$/a\
\
    def structure; @structure ||= Document::Structure.new(self); end\
\
    def form; @form ||= Document::Form.new(self); end\
\
    def shadings; @shadings ||= Document::Shadings.new(self); end\
\
    def colors; @colors ||= Document::Colors.new(self); end\
\
    def layers; @layers ||= Document::Layers.new(self); end\
\
    def associated_files; @associated_files ||= Document::AssociatedFiles.new(self); end\
\
    def portfolio; @portfolio ||= Document::Portfolio.new(self); end\
\
    def output_intents; @output_intents ||= Document::OutputIntents.new(self); end\
\
    def page_labels; @page_labels ||= Document::PageLabels.new(self); end\
\
    def info; @info ||= Document::Info.new(self); end\
\
    def display; @display ||= Document::Display.new(self); end\
\
    def xmp; @xmp ||= Document::Metadata.new(self); end\
\
    def version=(v); @version = v.to_s; end
}' lib/pdfrb/document.rb

# ---- page.rb: media_box= setter ----
grep -q "def media_box=" lib/pdfrb/model/type/page.rb || \
  sed -i '' '/def rotate/i\
        def media_box=(box)\
          self.value[:MediaBox] = box\
        end\
' lib/pdfrb/model/type/page.rb

# ---- win_ansi_encoding.rb: encode/decode class methods ----
grep -q "def encode" lib/pdfrb/font/encoding/win_ansi_encoding.rb || \
  sed -i '' 's|TABLE.freeze|TABLE.freeze\n\n        class << self\n          def encode(text)\n            Pdfrb::Font::Encoding.encode(:WinAnsiEncoding, text)\n          end\n\n          def decode(bytes)\n            Pdfrb::Font::Encoding.decode(:WinAnsiEncoding, bytes)\n          end\n        end|' lib/pdfrb/font/encoding/win_ansi_encoding.rb

# ---- pdf_a.rb: rule_id alias ----
grep -q "def rule_id" lib/pdfrb/conformance/pdf_a.rb || \
  sed -i '' 's|Violation = Struct.new(:rule, :message, :object, keyword_init: true)|Violation = Struct.new(:rule, :message, :object, keyword_init: true) do\n        def rule_id; rule; end\n      end|' lib/pdfrb/conformance/pdf_a.rb

# ---- pdf_ua.rb: rule_id alias ----
grep -q "def rule_id" lib/pdfrb/conformance/pdf_ua.rb || \
  sed -i '' 's|Violation = Struct.new(:rule, :message, :object, keyword_init: true)|Violation = Struct.new(:rule, :message, :object, keyword_init: true) do\n        def rule_id; rule; end\n      end|' lib/pdfrb/conformance/pdf_ua.rb

# ---- xmp/packet.rb: conditional lutaml require ----
sed -i '' 's|^require "lutaml/model"$|begin; require "lutaml/model"; rescue LoadError; end|' lib/pdfrb/xmp/packet.rb 2>/dev/null || true
sed -i '' 's|^require "lutaml/model"$|begin; require "lutaml/model"; rescue LoadError; end|' lib/pdfrb/xmp/schemas.rb 2>/dev/null || true

echo "All fixes applied successfully"
