# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # File-attachment annotation (s12.5.6.15). Embedded file displayed
      # as a paper-clip icon.
      class FileAttachmentAnnotation < MarkupAnnotation
        def embedded_file; self[:FS]; end
        def name; self[:Name]; end

        def icon_name
          (name || :PushPin).to_sym
        end

        def has_attachment?
          !!embedded_file
        end

        def resolved_file_spec
          ref = embedded_file
          return nil unless ref && document
          document.object(ref)
        end
      end
    end
  end
end
