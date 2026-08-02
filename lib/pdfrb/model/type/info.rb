# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Document info dict (s7.9.3). Title/Author/Subject/Keywords/
      # Creator/Producer/CreationDate/ModDate/Trapped.
      # Pre-PDF-2.0; superseded by /Metadata XMP in modern docs but
      # still widely used.
      class Info < Pdfrb::Model::Cos::Dictionary
        arlington_object "DocInfo"
      end
    end
  end
end
