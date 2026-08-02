# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # AcroForm interactive form root (s12.7.2). Catalog /AcroForm.
      class InteractiveForm < Pdfrb::Model::Cos::Dictionary
        arlington_object "InteractiveForm"
      end
    end
  end
end
