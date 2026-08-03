# frozen_string_literal: true

require "stringio"

module Pdfrb
  module Appearance
    # Generates /AP /N appearance streams for form fields and annotations.
    # Each method creates a Form XObject with the field's visual
    # representation and sets it as the /AP /N entry on the field.
    #
    # For PDF/A-4, /NeedAppearances must be false (or absent), so every
    # field needs a pre-computed appearance stream.
    class Generator
      DEFAULT_BORDER_WIDTH = 1.0
      DEFAULT_FONT_SIZE = 12
      DEFAULT_PADDING = 3

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Generate appearance for a text field.
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param value [String] the text value to display.
      # @param font_name [Symbol] resource name of the font.
      # @param font_size [Integer] point size.
      def text_field(field, value:, font_name: :Helv, font_size: DEFAULT_FONT_SIZE)
        rect = field.value[:Rect]
        return unless rect

        form = build_form_xobject(rect) do |canvas|
          draw_border(canvas, rect)
          if value && !value.to_s.empty?
            canvas.text(value.to_s,
                        at: [DEFAULT_PADDING, DEFAULT_PADDING],
                        font: font_name, size: font_size)
          end
        end

        set_appearance(field, form)
      end

      # Generate appearance for a checkbox.
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param checked [Boolean] whether the box is checked.
      def checkbox(field, checked:)
        rect = field.value[:Rect]
        return unless rect

        form = build_form_xobject(rect) do |canvas|
          draw_border(canvas, rect)
          if checked
            draw_check(canvas, rect)
          end
        end

        state_name = checked ? :Yes : :Off
        set_appearance(field, form, state_name)
        field.value[:AS] = state_name
      end

      # Generate appearance for a combo box (dropdown).
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param value [String] the selected value.
      # @param font_name [Symbol] resource name of the font.
      # @param font_size [Integer] point size.
      def combo(field, value:, font_name: :Helv, font_size: DEFAULT_FONT_SIZE)
        text_field(field, value: value, font_name: font_name, font_size: font_size)
      end

      # Generate appearance for a push button.
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param label [String] the button label.
      # @param font_name [Symbol] resource name of the font.
      def button(field, label:, font_name: :Helv)
        rect = field.value[:Rect]
        return unless rect

        form = build_form_xobject(rect) do |canvas|
          draw_border(canvas, rect)
          if label
            w = rect[2] - rect[0]
            h = rect[3] - rect[1]
            canvas.text(label,
                        at: [w / 3, h / 3],
                        font: font_name, size: DEFAULT_FONT_SIZE)
          end
        end

        set_appearance(field, form)
      end

      private

      def build_form_xobject(rect)
        x0, y0, x1, y1 = rect
        form = document.create_form_xobject(
          name: "AP",
          bbox: [0, 0, x1 - x0, y1 - y0]
        )
        canvas = form.canvas
        yield canvas
        form.finalize!
        form
      end

      def draw_border(canvas, rect)
        w = rect[2] - rect[0]
        h = rect[3] - rect[1]
        canvas.line_width = 0.5
        canvas.rectangle(0, 0, w, h)
        canvas.stroke
      end

      def draw_check(canvas, rect)
        w = rect[2] - rect[0]
        h = rect[3] - rect[1]
        m = [w * 0.2, h * 0.2].min
        canvas.line_width = 1.5
        canvas.line(m, m, w - m, h - m)
        canvas.line(m, h - m, w - m, m)
        canvas.stroke
      end

      def set_appearance(field, form, state_name = :Normal)
        form_stream = form.stream
        ref = Pdfrb::Model::Reference.new(form_stream.oid, form_stream.gen)

        ap = field.value[:AP]
        if ap.nil?
          ap = {}
          field.value[:AP] = ap
        end

        if state_name == :Normal
          ap[:N] = ref
        else
          n_dict = ap[:N].is_a?(::Hash) ? ap[:N] : {}
          n_dict[state_name] = ref
          ap[:N] = n_dict
        end
      end
    end
  end
end
