# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font Descriptor CIDType0 (s9.8). Specialised metrics for
      # CIDFontType0 (CFF-based CID fonts).
      class FontDescriptorCIDType0 < FontDescriptor
        def cid_font_type; 0; end

        def cff?; true; end
      end
    end
  end
end
