# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Compressed object stream (s7.5.7). /Type /ObjStm, /N count,
      # /First byte offset of first object, /Extends parent ObjStm.
      class ObjectStream < Pdfrb::Model::Cos::Stream
        arlington_object "ObjectStream"
        register_type :ObjStm
      end
    end
  end
end
