# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Filespec EF dict (s7.11.2.2). Maps variant file type to
      # EmbeddedFile stream reference: /F (type 1), /UF (Unicode),
      # /DOS, /Mac, /Unix.
      class FileSpecEF < Pdfrb::Model::Cos::Dictionary
        arlington_object "FileSpecEF"
        def primary_file; self[:F]; end
        def unicode_file; self[:UF]; end
        def dos_file; self[:DOS]; end
        def mac_file; self[:Mac]; end
        def unix_file; self[:Unix]; end

        def any?
          !!(primary_file || unicode_file || dos_file || mac_file || unix_file)
        end
      end
    end
  end
end
