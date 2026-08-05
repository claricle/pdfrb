# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font Descriptor CIDType2 (s9.8). Specialised metrics for
      # CIDFontType2 (TrueType-based CID fonts).
      class FontDescriptorCIDType2 < FontDescriptor
        def cid_font_type; 2; end

        def true_type?; true; end
      end
    end
  end
end
