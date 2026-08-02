# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Form XObject (s8.10). /Type /XObject, /Subtype /Form,
      # /BBox, /Matrix, /Resources, /Group, /Filter, etc.
      class XObjectForm < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectFormType1"
      end
    end
  end
end
