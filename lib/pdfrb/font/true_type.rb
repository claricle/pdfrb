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
      autoload :Maxp, "pdfrb/font/true_type/maxp"
      autoload :Post, "pdfrb/font/true_type/post"
      autoload :Name, "pdfrb/font/true_type/name"
      autoload :Loca, "pdfrb/font/true_type/loca"
      autoload :Glyf, "pdfrb/font/true_type/glyf"
      autoload :Kern, "pdfrb/font/true_type/kern"
      autoload :Wrapper, "pdfrb/font/true_type/wrapper"
      autoload :Subsetter, "pdfrb/font/true_type/subsetter"
    end
  end
end
