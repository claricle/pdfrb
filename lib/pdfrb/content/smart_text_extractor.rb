# frozen_string_literal: true

module Pdfrb
  module Content
    module SmartTextExtractor
      module_function

      def extract(document)
        results = []
        document.pages.each do |page|
          text = extract_page_text(document, page)
          results << { page: page, text: text }
        end

        block_given? ? yield(results) : results
      end

      def extract_page_text(document, page)
        contents = page.value[:Contents]
        return "" unless contents

        ref = contents.is_a?(Pdfrb::Model::Reference) ? contents : nil
        return "" unless ref

        stream = document.object(ref)
        return "" unless stream.is_a?(Pdfrb::Model::Cos::Stream)

        data = stream.decoded_stream
        return "" unless data && !data.empty?

        collector = TextCollector.new(document, page)
        begin
          collector.process(data)
        rescue StandardError
          # Best effort extraction
        end
        collector.text
      end

      class TextCollector < Pdfrb::Content::Processor
        attr_reader :text

        def initialize(document, page)
          super()
          @document = document
          @page = page
          @text = +""
          @last_y = nil
        end

        def show_text(str)
          insert_line_break_if_needed
          @text << decode_text(str)
        end

        def show_text_array(arr)
          insert_line_break_if_needed
          arr.each do |e|
            @text << decode_text(e) if e.is_a?(String)
          end
        end

        def move_text(tx, ty, **)
          super
          insert_line_break_if_needed
        end

        private

        def insert_line_break_if_needed
          cur_y = graphics_state.text_state.text_matrix.f
          if @last_y && (cur_y - @last_y).abs > 0.001
            @text << "\n"
          end
          @last_y = cur_y
        end

        def decode_text(bytes)
          bytes.to_s.dup.force_encoding("UTF-8")
        end
      end
      private_constant :TextCollector
    end
  end
end
