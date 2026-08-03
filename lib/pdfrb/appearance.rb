# frozen_string_literal: true

module Pdfrb
  # Appearance stream generation (ISO 32000-2 §12.5.5). Generates
  # /AP /N (normal appearance) streams for form fields and annotations
  # using the Canvas API. Required for PDF/A-4 compliance (which
  # prohibits /NeedAppearances).
  module Appearance
    autoload :Generator, "pdfrb/appearance/generator"
  end
end
