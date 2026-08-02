# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Image XObject (s8.9). /Type /XObject, /Subtype /Image,
      # /Width, /Height, /ColorSpace, /BitsPerComponent, etc.
      class XObjectImage < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectImage"
      end
    end
  end
end
