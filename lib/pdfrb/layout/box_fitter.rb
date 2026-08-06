# frozen_string_literal: true

module Pdfrb
  module Layout
    # Fits an ordered list of boxes into a Frame, flowing to a new
    # Frame (provided by a block) when one fills up.
    class BoxFitter
      attr_reader :boxes, :frame, :result, :overflow

      def initialize(boxes:, frame:)
        @boxes = boxes
        @frame = frame
        @result = []
        @overflow = []
      end

      def fit
        current_frame = @frame
        cursor_y = current_frame.top
        @boxes.each do |box|
          loop do
            position = current_frame.find_available_area(box.width || current_frame.width, box.height || (cursor_y - current_frame.bottom))
            if position && box.fit?(position[2] || current_frame.width, position[3] || (cursor_y - current_frame.bottom))
              @result << [box, position]
              current_frame.remove_area(position[0], position[1] - box.height, box.width, box.height)
              cursor_y = position[1] - box.height
              break
            else
              next_frame = yield if block_given?
              if next_frame
                current_frame = next_frame
                cursor_y = current_frame.top
              else
                @overflow << box
                break
              end
            end
          end
        end
        self
      end

      def draw(canvas)
        @result.each do |box, pos|
          box.draw(canvas, pos[0], pos[1])
        end
      end

      def fit_complete?
        @overflow.empty?
      end
    end
  end
end
