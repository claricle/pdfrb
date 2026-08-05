# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Filespec RF dict (s7.11.2.3). Related files name tree.
      class FileSpecRF < Pdfrb::Model::Cos::Dictionary
        def related_files; self[:Names]; end

        def each_related(&block)
          return enum_for(:each_related) unless block

          return unless related_files

          arr = related_files.is_a?(Pdfrb::Model::PdfArray) ? related_files.to_a : related_files
          arr.each_slice(2, &block)
        end
      end
    end
  end
end
