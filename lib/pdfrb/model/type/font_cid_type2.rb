# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font CIDType2 (s9.7.3). CIDFontType2 — CID-keyed font based
      # on TrueType outlines.
      class FontCIDType2 < CIDFont
        arlington_object "FontCIDType2"
        def cid_subtype; self[:Subtype]&.to_sym; end

        def true_type?
          cid_subtype == :CIDFontType2
        end
      end
    end
  end
end
