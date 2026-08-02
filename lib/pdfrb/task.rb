# frozen_string_literal: true

module Pdfrb
  # Bulk operations on a Document. Each task is a module under Task::*
  # with a `.call(document, **opts)` class method. Adding a new task
  # = adding one module file (open/closed via the CLI wiring).
  module Task
    autoload :ExtractText, "pdfrb/task/extract_text"
    autoload :ExtractImages, "pdfrb/task/extract_images"
    autoload :Merge, "pdfrb/task/merge"
    autoload :Optimize, "pdfrb/task/optimize"
  end
end
