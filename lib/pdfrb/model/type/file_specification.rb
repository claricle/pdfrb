# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # File specification (s7.11.2). /FS, /F, /UF, /EF, /Desc, etc.
      class FileSpecification < Pdfrb::Model::Cos::Dictionary
        arlington_object "FileSpecification"
      end
    end
  end
end
