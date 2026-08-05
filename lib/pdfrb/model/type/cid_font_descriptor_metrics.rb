# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CID Font Descriptor Metrics (s9.8.1, Table 117). Per-CIDFont
      # metrics used for embedded CIDFontType0/CIDFontType2.
      class CIDFontDescriptorMetrics < Pdfrb::Model::Cos::Dictionary
        def style; self[:Style]&.to_sym; end
        def cid_set; self[:CIDSet]; end

        def monospaced?; style == :Monospaced; end
        def proportional?; style == :Proportional; end

        def has_cid_set?
          !!cid_set
        end

        def resolved_cid_set
          ref = cid_set
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
