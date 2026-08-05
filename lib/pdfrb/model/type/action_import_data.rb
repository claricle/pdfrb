# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Import-data action (s12.7.6.4). Imports form data from an FDF/XFDF file.
      class ActionImportData < Action
        register_subtype :ImportData

        def file_spec; self[:F]; end

        def has_file?
          !!file_spec
        end
      end
    end
  end
end
