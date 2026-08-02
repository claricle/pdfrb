# frozen_string_literal: true

module Pdfrb
  module Model
    # COS value layer: literal PDF types and the Dictionary field system
    # that drives semantic Type subclasses.
    #
    # Scalars use native Ruby types wherever possible (no wrapper classes):
    #   true/false, Integer, Float, Symbol (Name), String, nil (Null).
    # Helpers for Name encode/decode and String text/binary conversion
    # live in Cos::NameEncoding and Cos::StringEncoding.
    module Cos
      autoload :Fields, "pdfrb/model/cos/fields"
      autoload :NameEncoding, "pdfrb/model/cos/name_encoding"
      autoload :StringEncoding, "pdfrb/model/cos/string_encoding"
      autoload :Dictionary, "pdfrb/model/cos/dictionary"
      autoload :Stream, "pdfrb/model/cos/stream"
    end
  end
end
