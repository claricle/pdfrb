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

      # Generate appearance for a radio button.
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param selected [String] the selected state name (e.g. :Yes).
      # @param options [Array<String>] all possible state names.
      def radio_button(field, selected:, options: [:Yes])
        rect = field.value[:Rect]
        return unless rect

        options.each do |state|
          form = build_form_xobject(rect) do |canvas|
            draw_border(canvas, rect)
            draw_radio_circle(canvas, rect, selected: state == selected)
          end
          set_appearance(field, form, state_name: state.to_sym)
        end
        field.value[:AS] = selected.to_sym
      end

      # Generate appearance for a list box field.
      # @param field [Pdfrb::Model::Type::Annotation] the Widget/field.
      # @param items [Array<String>] the list items to show.
      # @param selected [Integer, nil] index of the selected item.
      # @param font_name [Symbol] resource name of the font.
      # @param font_size [Integer] point size.
      def list_box(field, items:, selected: nil, font_name: :Helv,
                   font_size: DEFAULT_FONT_SIZE)
        rect = field.value[:Rect]
        return unless rect

        form = build_form_xobject(rect) do |canvas|
          draw_border(canvas, rect)
          items.each_with_index do |item, i|
            y_pos = (rect[3] - rect[1]) - DEFAULT_PADDING - ((i + 1) * font_size)
            break if y_pos.negative?

            if i == selected
              w = rect[2] - rect[0]
              canvas.fill_color([0.8, 0.8, 1.0])
              canvas.rectangle(0, y_pos - 2, w, font_size + 4)
              canvas.fill
              canvas.fill_color([0, 0, 0])
            end
            canvas.text(item.to_s, at: [DEFAULT_PADDING, y_pos],
                                   font: font_name, size: font_size)
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

      def draw_radio_circle(canvas, rect, selected:)
        w = rect[2] - rect[0]
        h = rect[3] - rect[1]
        r = ([w, h].min / 2) - 1
        cx = w / 2
        cy = h / 2
        canvas.line_width = 1.0

        # Approximate a circle with a rectangle for now (Canvas lacks arc).
        canvas.rectangle(cx - r, cy - r, r * 2, r * 2)
        canvas.stroke

        if selected
          canvas.line_width = 2.0
          inner_r = r * 0.4
          canvas.rectangle(cx - inner_r, cy - inner_r, inner_r * 2, inner_r * 2)
          canvas.fill
        end
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
        ref = form_stream.ref

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
