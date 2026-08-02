# frozen_string_literal: true

module Pdfrb
  module Content
    # Immutable snapshot of the PDF graphics state (s8.4). The
    # +Processor+ holds a stack of these for `q` (push) / `Q` (pop).
    # Subclasses (TextState for the text sub-state) compose rather
    # than inherit.
    class GraphicsState
      attr_reader :ctm, :text_state, :fill_color, :stroke_color,
                  :line_width, :line_cap, :line_join, :miter_limit,
                  :dash_pattern, :flatness, :alpha_is_shape,
                  :stroke_alpha, :fill_alpha, :blend_mode, :soft_mask,
                  :overprint, :overprint_mode

      def initialize(ctm: Pdfrb::Model::Matrix.identity,
                     text_state: TextState.new,
                     fill_color: nil, stroke_color: nil,
                     line_width: 1.0, line_cap: 0, line_join: 0,
                     miter_limit: 10.0, dash_pattern: [].freeze,
                     flatness: 0, alpha_is_shape: false,
                     stroke_alpha: 1.0, fill_alpha: 1.0,
                     blend_mode: :Normal, soft_mask: nil,
                     overprint: false, overprint_mode: 0)
        @ctm = ctm
        @text_state = text_state
        @fill_color = fill_color
        @stroke_color = stroke_color
        @line_width = line_width.to_f
        @line_cap = line_cap.to_i
        @line_join = line_join.to_i
        @miter_limit = miter_limit.to_f
        @dash_pattern = dash_pattern
        @flatness = flatness.to_i
        @alpha_is_shape = alpha_is_shape
        @stroke_alpha = stroke_alpha.to_f
        @fill_alpha = fill_alpha.to_f
        @blend_mode = blend_mode
        @soft_mask = soft_mask
        @overprint = overprint
        @overprint_mode = overprint_mode.to_i
      end

      # Returns a new GraphicsState with the given overrides (the
      # original is frozen).
      def with(**overrides)
        GraphicsState.new(**to_h.merge(overrides))
      end

      def to_h
        {
          ctm: @ctm, text_state: @text_state,
          fill_color: @fill_color, stroke_color: @stroke_color,
          line_width: @line_width, line_cap: @line_cap,
          line_join: @line_join, miter_limit: @miter_limit,
          dash_pattern: @dash_pattern, flatness: @flatness,
          alpha_is_shape: @alpha_is_shape, stroke_alpha: @stroke_alpha,
          fill_alpha: @fill_alpha, blend_mode: @blend_mode,
          soft_mask: @soft_mask, overprint: @overprint,
          overprint_mode: @overprint_mode
        }
      end

      # Text-specific sub-state (s9.3). Composed in GraphicsState.
      class TextState
        attr_reader :char_spacing, :word_spacing, :horizontal_scaling,
                    :leading, :font_name, :font_size,
                    :rendering_mode, :rise, :text_matrix, :line_matrix

        def initialize(char_spacing: 0.0, word_spacing: 0.0,
                       horizontal_scaling: 100.0, leading: 0.0,
                       font_name: nil, font_size: 0.0,
                       rendering_mode: 0, rise: 0.0,
                       text_matrix: Pdfrb::Model::Matrix.identity,
                       line_matrix: Pdfrb::Model::Matrix.identity)
          @char_spacing = char_spacing.to_f
          @word_spacing = word_spacing.to_f
          @horizontal_scaling = horizontal_scaling.to_f
          @leading = leading.to_f
          @font_name = font_name
          @font_size = font_size.to_f
          @rendering_mode = rendering_mode.to_i
          @rise = rise.to_f
          @text_matrix = text_matrix
          @line_matrix = line_matrix
        end

        def with(**overrides)
          TextState.new(**to_h.merge(overrides))
        end

        def to_h
          {
            char_spacing: @char_spacing, word_spacing: @word_spacing,
            horizontal_scaling: @horizontal_scaling, leading: @leading,
            font_name: @font_name, font_size: @font_size,
            rendering_mode: @rendering_mode, rise: @rise,
            text_matrix: @text_matrix, line_matrix: @line_matrix
          }
        end
      end
    end
  end
end
