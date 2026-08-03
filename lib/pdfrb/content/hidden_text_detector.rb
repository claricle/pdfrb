# frozen_string_literal: true

require "stringio"

module Pdfrb
  module Content
    # Detects hidden / transparent text in content streams. Hidden text
    # is text rendered with Tr=3 (invisible) or with alpha=0 (fully
    # transparent). PDF/A and PDF/UA require such text to be tagged as
    # /Artifact or wrapped in a structure element.
    #
    # Inspired by mn2pdf's PDFHiddenTextStripper. Walks content streams
    # via the Content::Parser, tracking graphics state changes.
    class HiddenTextDetector
      HiddenItem = Struct.new(:text, :reason, :page, keyword_init: true) do
        def hidden?
          !reason.nil?
        end
      end

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Walk all content streams. Returns HiddenItem objects for each
      # text-showing operation. Items with a nil reason are visible.
      def detect
        items = []
        @document.each_indirect_object do |obj|
          next unless content_stream?(obj)

          page = find_page(obj)
          detect_in_stream(obj, page) { |item| items << item }
        end
        items
      end

      # Returns only the hidden text items (rendering_mode_3 or alpha=0).
      def hidden_only
        detect.select(&:hidden?)
      end

      private

      def content_stream?(obj)
        return false unless obj.is_a?(Pdfrb::Model::Cos::Stream)
        return true if obj.value[:Type] == :Page

        subtype = obj.value[:Subtype]
        return false if subtype == :Image

        true
      end

      def find_page(stream_obj)
        @document.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)
          next unless obj[:Type] == :Page

          contents = obj[:Contents]
          next unless contents

          list = if contents.is_a?(Pdfrb::Model::PdfArray)
                   contents.value
                 else
                   contents.is_a?(::Array) ? contents : [contents]
                 end

          return obj if list.any? do |c|
            c_obj = c.is_a?(Pdfrb::Model::Reference) ? @document.object(c) : c
            c_obj == stream_obj
          end
        end
        nil
      end

      def detect_in_stream(stream_obj, page, &block)
        bytes = stream_obj.stream
        return unless bytes && !bytes.empty?

        io = StringIO.new(bytes.b)
        tokenizer = Pdfrb::Source::Tokenizer.new(io)
        parser = Content::Parser.new(tokenizer)
        collector = Collector.new(page)

        parser.each_invocation do |op_class, operands|
          op_name = op_class.name
          case op_name
          when "Tr"
            collector.text_rendering_mode = operands.first.to_i if operands.first
          when "ca"
            collector.stroke_alpha = operands.first.to_f if operands.first
          when "CA"
            collector.non_stroke_alpha = operands.first.to_f if operands.first
          when "Tj"
            collector.show_text(operands.first)
          when "TJ"
            collector.show_text_array(operands.first)
          when "'", "\""
            collector.move_to_next_line
            collector.show_text(operands.first) if operands.first
          end
        end

        collector.items.each(&block)
      rescue StandardError
        nil
      end

      # Internal: collects text-show operations with their visibility state.
      class Collector
        attr_reader :items

        def initialize(page)
          @items = []
          @page = page
          @text_rendering_mode = 0
          @non_stroke_alpha = 1.0
          @stroke_alpha = 1.0
        end

        def text_rendering_mode=(value)
          @text_rendering_mode = value
        end

        def non_stroke_alpha=(value)
          @non_stroke_alpha = value
        end

        def stroke_alpha=(value)
          @stroke_alpha = value
        end

        def show_text(text)
          return if text.nil?

          reason = current_reason
          @items << HiddenItem.new(text: text.to_s, reason: reason, page: @page)
        end

        def show_text_array(items)
          return unless items.is_a?(::Array)

          items.each do |item|
            if item.is_a?(::String)
              show_text(item)
            end
            # Numeric items are positioning values; ignore them
          end
        end

        def move_to_next_line; end

        private

        def current_reason
          return :rendering_mode_invisible if @text_rendering_mode == 3
          return :alpha_zero_hidden if @non_stroke_alpha.to_f == 0.0 || @stroke_alpha.to_f == 0.0

          nil
        end
      end
    end
  end
end
