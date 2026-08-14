# frozen_string_literal: true

module Pdfrb
  module Layout
    # Fits an ordered list of boxes into a Frame, flowing to a new
    # Frame (provided by a block) when one fills up. Delegates area
    # tracking to the Frame (which now properly tracks removed areas
    # and returns non-overlapping positions).
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
        @boxes.each do |box|
          current_frame = fit_box(box, current_frame)
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

      private

      def fit_box(box, frame)
        loop do
          return frame if place?(box, frame)

          next_frame = yield if block_given?
          unless next_frame
            @overflow << box
            return frame
          end

          frame = next_frame
        end
      end

      def place?(box, frame)
        box_w = box.width || frame.width
        box_h = box.height || frame.available_height
        position = frame.find_available_area(box_w, box_h)
        return false unless position

        actual_w = position[2] || frame.width
        actual_h = position[3] || frame.available_height
        return false unless box.fit?(actual_w, actual_h)

        @result << [box, position]
        frame.remove_area(position[0], position[1], actual_w, box.height || actual_h)
        true
      end
    end
  end
end
