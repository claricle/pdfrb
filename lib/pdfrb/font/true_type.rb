# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      autoload :File, "pdfrb/font/true_type/file"
      autoload :Head, "pdfrb/font/true_type/head"
      autoload :Hhea, "pdfrb/font/true_type/hhea"
      autoload :Hmtx, "pdfrb/font/true_type/hmtx"
      autoload :Cmap, "pdfrb/font/true_type/cmap"
      autoload :OS2, "pdfrb/font/true_type/os2"
    end
  end
end
