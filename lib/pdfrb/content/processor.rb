# frozen_string_literal: true

module Pdfrb
  module Content
    # Walks a content stream through the operator registry, updating
    # the current +GraphicsState+ and dispatching to per-operator
    # hooks (paint_path, show_text, ...). Subclasses override the
    # hooks to render / extract / re-emit.
    #
    # Mirrors HexaPDF::Content::Processor.
    class Processor
      attr_reader :graphics_state, :state_stack

      def initialize
        @graphics_state = GraphicsState.new
        @state_stack = []
      end

      # Feed +bytes+ (or IO) through the parser, invoking each
      # operator against this processor.
      def process(io_or_string)
        Parser.parse(io_or_string).each_invocation do |op_class, operands|
          op_class.invoke(self, *operands)
        end
        self
      end

      # ---- Graphics-state stack ----

      def push_graphics_state
        @state_stack.push(@graphics_state)
      end

      def pop_graphics_state
        @graphics_state = @state_stack.pop || @graphics_state
      end

      def update_graphics_state(**overrides)
        @graphics_state = @graphics_state.with(**overrides)
      end

      def update_text_state(**overrides)
        new_ts = @graphics_state.text_state.with(**overrides)
        @graphics_state = @graphics_state.with(text_state: new_ts)
      end

      # ---- Text positioning ----

      def move_text(tx, ty, set_leading: false, neg_leading: false)
        ts = @graphics_state.text_state
        ts = ts.with(leading: -ty.to_f) if set_leading && neg_leading
        ts = ts.with(leading: ty.to_f) if set_leading && !neg_leading
        translation = Pdfrb::Model::Matrix.translate(tx.to_f, ty.to_f)
        new_line = translation * ts.line_matrix
        new_text = translation * ts.text_matrix
        update_text_state(line_matrix: new_line, text_matrix: new_text, leading: ts.leading)
      end

      def set_text_matrix(m)
        update_text_state(text_matrix: m, line_matrix: m)
      end

      # ---- Hooks (subclasses override) ----

      def show_text(_str); end
      def show_text_array(_array); end
      def paint_path(fill:, stroke:, close:, rule:); end
      def path_move_to(_x, _y); end
      def path_line_to(_x, _y); end
      def path_curve_to(_p1, _p2, _p3); end
      def path_close; end
      def path_rectangle(_x, _y, _w, _h); end
      def path_end; end
      def apply_extgstate(_name); end

      def begin_marked_content(_tag, _properties = nil); end
      def end_marked_content; end
      def marked_content_point(_tag, _properties = nil); end
    end
  end
end
