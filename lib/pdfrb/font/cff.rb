# frozen_string_literal: true

module Pdfrb
  module Font
    # CFF (Compact Font Format, ISO 32000-2 Annex / Adobe CFF spec
    # TN5176) parsing and safe subsetting for OTF fonts embedded via
    # /FontFile3 /Subtype /OpenType.
    #
    # Layout: header, Name INDEX, Top DICT INDEX, String INDEX,
    # Global Subr INDEX, then (at offsets recorded in the Top DICT)
    # charset, CharStrings INDEX, Private DICT (+ Local Subr INDEX).
    module CFF
      autoload :Index, "pdfrb/font/cff/index"
      autoload :Dict, "pdfrb/font/cff/dict"
      autoload :File, "pdfrb/font/cff/file"
      autoload :Subsetter, "pdfrb/font/cff/subsetter"
    end
  end
end
