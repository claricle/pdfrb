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
          flags.anybits?(1)
        end

        def include_no_value_fields?
          flags.anybits?(2)
        end

        def export_format?
          flags.anybits?(4)
        end

        def get_method?
          flags.anybits?(8)
        end

        def submit_coordinates?
          flags.anybits?(16)
        end

        def submit_as_xfdf?
          flags.anybits?(32)
        end

        def submit_as_append?
          flags.anybits?(64)
        end

        def submit_as_pdf?
          flags.anybits?(256)
        end

        def canonical_date_format?
          flags.anybits?(512)
        end

        def submit_as_xfdf_with_annotations?
          flags.anybits?(1024)
        end

        def submit_as_xdp?
          flags.anybits?(2048)
        end

        def submit_as_xfdf_charset?
          flags.anybits?(4096)
        end
      end
    end
  end
end
