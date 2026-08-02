# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font descriptor (s9.8). Carries metrics + embedded font file.
      class FontDescriptor < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontDescriptorType1"
      end
    end
  end
end
