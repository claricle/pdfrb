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

      def save_graphics_state(&)
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

      def translate(tx, ty, &)
        concat(1, 0, 0, 1, tx, ty, &)
      end

      def scale(sx, sy = sx, &)
        concat(sx, 0, 0, sy, 0, 0, &)
      end

      def rotate(angle_in_radians, &)
        c = Math.cos(angle_in_radians)
        s = Math.sin(angle_in_radians)
        concat(c, s, -s, c, 0, 0, &)
      end

      def concat(a, b, c, d, e, f, &)
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

      # Draw a Form XObject by resource name at (x, y) with an optional
      # matrix transform. Public API for page stamping, form flattening,
      # and appearance-stream embedding.
      # @param name [Symbol] the resource name in /Resources /XObject.
      # @param at [Array<Numeric>] x, y translation.
      # @param matrix [Array<Numeric>, nil] 6-element transform matrix.
      def draw_form_xobject(name, at: [0, 0], matrix: nil)
        @used_xobjects[name] = true
        save_graphics_state do
          if matrix
            a, b, c, d, e, f = matrix
            concat(a, b, c, d, e, f)
          elsif at
            translate(at[0], at[1])
          end
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
        lead = leading || (size * 1.2)
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

      def marked_content(tag, properties = nil, &)
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

      def tagged(tag, mcid: nil, **props, &)
        p = props.dup
        p[:MCID] = mcid if mcid
        p = nil if p.empty?
        marked_content(tag, p, &)
      end

      def artifact(type = nil, &)
        if type
          marked_content(:Artifact, { Type: type }, &)
        else
          marked_content(:Artifact, &)
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
