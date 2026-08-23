# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font CIDType0 (s9.7.3). CIDFontType0 — CID-keyed font based
      # on CFF (Compact Font Format).
      class FontCIDType0 < CIDFont
        arlington_object "FontCIDType0"
        def cid_subtype; self[:Subtype]&.to_sym; end

        def cff?
          cid_subtype == :CIDFontType0
        end
      end
    end
  end
end
