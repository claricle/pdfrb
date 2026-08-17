# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Submit-form action (s12.7.6.2). Submits form values to a URL.
      class ActionSubmitForm < Action
        arlington_object "ActionSubmitForm"
        register_subtype :SubmitForm

        def url; self[:F]; end
        def fields; self[:Fields]; end
        def flags; self[:Flags] || 0; end

        def include_exclude?
          flags & 1 != 0
        end

        def include_no_value_fields?
          flags & 2 != 0
        end

        def export_format?
          flags & 4 != 0
        end

        def get_method?
          flags & 8 != 0
        end

        def submit_coordinates?
          flags & 16 != 0
        end

        def submit_as_xfdf?
          flags & 32 != 0
        end

        def submit_as_append?
          flags & 64 != 0
        end

        def submit_as_pdf?
          flags & 256 != 0
        end

        def canonical_date_format?
          flags & 512 != 0
        end

        def submit_as_xfdf_with_annotations?
          flags & 1024 != 0
        end

        def submit_as_xdp?
          flags & 2048 != 0
        end

        def submit_as_xfdf_charset?
          flags & 4096 != 0
        end
      end
    end
  end
end
