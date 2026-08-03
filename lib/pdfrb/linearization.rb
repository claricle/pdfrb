# frozen_string_literal: true

module Pdfrb
  # Linearization (PDF 1.2+ fast-web-view, ISO 32000-2 §7.6.2 + Annex F).
  #
  # A linearized PDF is structured so the first page's data appears near
  # the front of the file, enabling incremental download and display.
  # The structure has:
  #   Part 1: Linearization parameter dict + first-page xref
  #   Part 2: First page's document objects
  #   Part 3: Remaining pages' objects
  #   Part 4: Hint stream (page-offset + shared-object tables)
  #   Part 5: Main xref + trailer
  #
  # Detection: see Pdfrb::Source::LinearizationDetection.
  # Writing: see Pdfrb::Linearization::Writer.
  module Linearization
    autoload :Writer, "pdfrb/linearization/writer"
    autoload :HintStream, "pdfrb/linearization/hint_stream"
  end
end
