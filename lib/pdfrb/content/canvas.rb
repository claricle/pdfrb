# frozen_string_literal: true

module Pdfrb
  module Content
    # High-level drawing API on a Stream (page /Contents or Form
    # XObject). The Canvas emits operators via the +Serializer+ and
    # appends the bytes to the Stream's raw payload.
    #
    # Methods mirror HexaPDF::Content::Canvas where the names are
    # intuitive; PDF-specific concepts (q/Q, marked content) are
    # exposed via Ruby-block syntax.
    class Canvas
      attr_reader :stream, :document, :serializer

      def initialize(stream, document: nil)
        @stream = stream
        @document = document || stream.document
        @serializer = Pdfrb::Serializer.new
        ensure_stream_payload
      end

      # ---- State stack ----

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

      # ---- Transforms ----

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
          # Reverse by save/restore so the caller's matrix is unchanged.
          emit_op Pdfrb::Content::Operator::SaveGraphicsState
        end
        self
      end

      # ---- Path construction ----

      def move_to(x, y)
        emit_op Pdfrb::Content::Operator::MoveTo, x, y
        self
      end

      def line_to(x, y)
        emit_op Pdfrb::Content::Operator::LineTo, x, y
        self
      end

      def line(x1, y1, x2, y2)
        move_to(x1, y1).line_to(x2, y2)
      end

      def curve_to(c1x, c1y, c2x, c2y, x, y)
        emit_op Pdfrb::Content::Operator::CurveTo, c1x, c1y, c2x, c2y, x, y
        self
      end

      def rectangle(x, y, width, height)
        emit_op Pdfrb::Content::Operator::Rectangle, x, y, width, height
        self
      end

      def close_path
        emit_op Pdfrb::Content::Operator::ClosePath
        self
      end

      # ---- Painting ----

      def stroke
        emit_op Pdfrb::Content::Operator::Stroke
        self
      end

      def fill(rule: :nonzero)
        op = rule == :even_odd ?
               Pdfrb::Content::Operator::FillEvenOdd :
               Pdfrb::Content::Operator::FillNonZero
        emit_op op
        self
      end

      def fill_stroke(rule: :nonzero)
        op = rule == :even_odd ?
               Pdfrb::Content::Operator::FillStrokeEvenOdd :
               Pdfrb::Content::Operator::FillStrokeNonZero
        emit_op op
        self
      end

      def end_path
        emit_op Pdfrb::Content::Operator::EndPath
        self
      end

      # ---- Color ----

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

      # ---- Text ----

      # Show +text+ at (+x+, +y+) in the named font. Caller is
      # responsible for registering the font in the page resources
      # under +font_name+ before this call.
      def text(str, at:, font:, size:, char_spacing: nil, word_spacing: nil)
        emit_op Pdfrb::Content::Operator::BeginText
        emit_op Pdfrb::Content::Operator::SetTextMatrix,
                1, 0, 0, 1, at[0], at[1]
        emit_op Pdfrb::Content::Operator::Font, font, size
        emit_op Pdfrb::Content::Operator::CharSpacing, char_spacing if char_spacing
        emit_op Pdfrb::Content::Operator::WordSpacing, word_spacing if word_spacing
        emit_op Pdfrb::Content::Operator::ShowText, str.to_s
        emit_op Pdfrb::Content::Operator::EndText
        self
      end

      # ---- Graphics-state params ----

      def line_width=(n)
        emit_op Pdfrb::Content::Operator::LineWidth, n
      end

      def line_cap=(n)
        emit_op Pdfrb::Content::Operator::LineCap, n
      end

      def line_join=(n)
        emit_op Pdfrb::Content::Operator::LineJoin, n
      end

      def miter_limit=(n)
        emit_op Pdfrb::Content::Operator::MiterLimit, n
      end

      def dash_pattern=(spec)
        if spec.is_a?(::Array)
          array, phase = spec
        else
          array, phase = spec, 0
        end
        emit_op Pdfrb::Content::Operator::DashPattern, array, phase
      end

      # ---- Marked content ----

      def marked_content(tag, properties = nil, &block)
        if properties
          emit_op Pdfrb::Content::Operator::BeginMarkedContentWithProperties, tag, properties
        else
          emit_op Pdfrb::Content::Operator::BeginMarkedContent, tag
        end
        return self unless block_given?

        begin
          yield self
        ensure
          emit_op Pdfrb::Content::Operator::EndMarkedContent
        end
        self
      end

      # ---- Internal ----

      def emit_op(op_class, *operands)
        bytes = op_class.serialize(@serializer, *operands)
        append(bytes)
      end

      private

      def ensure_stream_payload
        return if @stream.stream.is_a?(::String)

        @stream.stream = ""
      end

      def append(bytes)
        new_payload = (@stream.stream || +"") + bytes.to_s
        @stream.stream = new_payload
      end

      def emit_color_op(fill, family, rest)
        klass = color_op_class(family, fill)
        emit_op(klass, *rest)
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
    end
  end
end
