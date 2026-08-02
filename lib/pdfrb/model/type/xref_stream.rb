# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Cross-reference stream (s7.5.8, PDF 1.5+). Doubles as the
      # trailer dict in PDF 1.5+ documents.
      class XRefStream < Pdfrb::Model::Cos::Stream
        arlington_object "XRefStream"
        register_type :XRef
      end
    end
  end
end
