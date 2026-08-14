# frozen_string_literal: true

module Pdfrb
  # High-level document composition API. Wraps a +Document+ and a
  # +Layout::BoxFitter+, exposing a DSL for adding text, images, and
  # boxes with automatic page flow.
  #
  # Usage:
  #   Pdfrb::Composer.new("out.pdf") do |c|
  #     c.style(:heading, font_size: 24)
  #     c.text("Hello world", style: :heading)
  #     c.image("/path/to/logo.png", width: 200)
  #     c.text("Body text flows naturally.")
  #   end
  class Composer
    DEFAULT_PAGE_STYLE = :default

    attr_reader :document, :page_styles, :current_page, :current_style_name

    def initialize(output = nil, page_size: :A4, page_orientation: :portrait,
                   margin: 36, skip_page_creation: false)
      @document = Pdfrb::Document.new
      @page_styles = {}
      @output_target = output
      @pending_boxes = []

      page_style(DEFAULT_PAGE_STYLE, page_size: page_size,
                                     orientation: page_orientation,
                                     margin: margin)
      @current_style_name = DEFAULT_PAGE_STYLE
      new_page unless skip_page_creation
    end

    # Class-level shortcut: create a document, yield to block, write.
    def self.create(output, **)
      composer = new(output, **)
      yield composer
      composer.write
    end

    # Define a named text style.
    def style(name, base: :base, **properties)
      @styles ||= {}
      @styles[name.to_sym] = Layout::Style.new(base, **properties)
    end

    def style?(name)
      @styles&.key?(name.to_sym)
    end

    # Define a named page style.
    def page_style(name, **attrs, &)
      @page_styles[name.to_sym] = Layout::PageStyle.new(name: name, **attrs, &)
    end

    # Create a new page using the named (or current) page style.
    def new_page(style_name = nil)
      @current_style_name = style_name || next_style_name
      style_obj = @page_styles[@current_style_name]
      # Reset the frame cursor for the new page.
      reset_frame_cursor(style_obj)
      page = @document.pages.add
      page.value[:MediaBox] = [0, 0, style_obj.width, style_obj.height]
      @current_page = page
      @pending_boxes = []
      page
    end

    def reset_frame_cursor(style_obj)
      style_obj&.frame&.reset!
    end
    private :reset_frame_cursor

    def x
      @cursor_x || 50
    end

    def y
      @cursor_y || (@current_page ? 750 : 0)
    end

    # Add text using a style.
    def text(str, width: 0, height: 0, style: nil, **style_properties)
      resolved_style = resolve_style(style, style_properties)
      box = Layout::TextBox.new(text: str, width: width, height: height,
                                style: resolved_style)
      draw_box_on_current_page(box)
    end

    # Add formatted text (array of {text:, style:} runs).
    def formatted_text(data, **opts)
      data.each { |run| text(run[:text], **opts, **run.fetch(:style, {})) }
    end

    # Add an image from a file path.
    def image(path, width: 0, height: 0, **opts)
      box = Layout::ImageBox.new(path: path, document: @document,
                                 width: width, height: height)
      draw_box_on_current_page(box)
    end

    # Add an arbitrary box.
    def box(box_class, **, &)
      box = box_class.new(**, &)
      draw_box_on_current_page(box)
    end

    # Write the document.
    def write(output = @output_target, optimize: false, **opts)
      flush_pending_boxes
      target = output
      if target.is_a?(String)
        @document.write(target)
      else
        @document.write(io: target)
      end
    end

    def write_to_string(optimize: false, **)
      require "stringio"
      io = StringIO.new
      write(io, optimize: optimize, **)
      io.string
    end

    private

    def next_style_name
      current = @page_styles[@current_style_name]
      current&.next_style || @current_style_name
    end

    def resolve_style(name, properties)
      if name.is_a?(Layout::Style)
        properties.empty? ? name : name.update(**properties)
      elsif @styles && @styles[name.to_sym]
        base = @styles[name.to_sym]
        properties.empty? ? base : base.update(**properties)
      else
        Layout::Style.new(properties.empty? ? :base : properties)
      end
    end

    def draw_box_on_current_page(box)
      @pending_boxes << box
    end

    def flush_pending_boxes
      return if @pending_boxes.empty?

      style_obj = @page_styles[@current_style_name]
      frame = style_obj.frame

      @pending_boxes.each do |box|
        available_h = frame.available_height.positive? ? frame.available_height : (frame.top - frame.bottom)
        unless box.fit?(frame.width, available_h)
          new_page
          style_obj = @page_styles[@current_style_name]
          frame = style_obj.frame
          available_h = frame.top - frame.bottom
          box.fit?(frame.width, available_h)
        end

        position = frame.find_available_area(box.width || frame.width, box.height || available_h)
        if position
          draw_x, draw_y, = position
        else
          draw_x = frame.left
          draw_y = frame.cursor_y - (box.height || 0)
        end

        canvas = @current_page.canvas
        box.draw(canvas, draw_x, draw_y)
        box_h = box.height || available_h
        frame.remove_area(draw_x, draw_y, box.width || frame.width, box_h)
      end
      @pending_boxes = []
    end
  end
end
