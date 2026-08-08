# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # File specification (s7.11.2). /FS, /F, /UF, /EF, /Desc, etc.
      class FileSpecification < Pdfrb::Model::Cos::Dictionary
        arlington_object "FileSpecification"
        register_type :Filespec

        def file_system; self[:FS]; end
        def file; self[:F]; end
        def unicode_file; self[:UF]; end
        def dos_file; self[:DOS]; end
        def mac_file; self[:Mac]; end
        def unix_file; self[:Unix]; end
        def id; self[:ID]; end
        def volatile; self[:V]; end
        def embedded_file; self[:EF]; end
        def related_files; self[:RF]; end
        def description; self[:Desc]; end
        def collection; self[:Collection]; end
        def type; self[:Type]; end

        def simple?
          !!(file || unicode_file)
        end

        def url?
          file_system&.to_sym == :URL
        end

        def effective_filename
          unicode_file || file || dos_file || mac_file || unix_file
        end

        def effective_embedded_file
          return nil unless embedded_file

          mapping = if embedded_file.is_a?(Pdfrb::Model::Reference) && document
                      document.object(embedded_file)
                    else
                      embedded_file
                    end
          return nil unless mapping.is_a?(Hash)

          ref = mapping[:UF] || mapping[:F]
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
