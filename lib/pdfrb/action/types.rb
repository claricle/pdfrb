# frozen_string_literal: true

module Pdfrb
  module Action
    # Concrete action types (ISO 32000-2 §12.6). Each class defines
    # its /S value and type-specific fields, then registers itself.

    # GoTo — jump to a destination in the current document. §12.6.4.2
    class GoTo < Base
      class << self
        def action_type; :GoTo; end

        def to_pdf(dest:)
          { S: :GoTo, D: dest }
        end
      end
      register_as
    end

    # URI — open a Uniform Resource Identifier. §12.6.4.7
    class URI < Base
      class << self
        def action_type; :URI; end

        def to_pdf(uri:, is_map: false)
          { S: :URI, URI: uri, IsMap: is_map }.compact
        end
      end
      register_as
    end

    # Launch — launch an external application. §12.6.4.5
    class Launch < Base
      class << self
        def action_type; :Launch; end

        def to_pdf(file_spec:, new_window: nil)
          payload = { S: :Launch, F: file_spec }
          payload[:NewWindow] = new_window unless new_window.nil?
          payload
        end
      end
      register_as
    end

    # Named — execute a named action predefined by the viewer. §12.6.4.11
    class Named < Base
      class << self
        def action_type; :Named; end

        def to_pdf(name:)
          { S: :Named, N: name }
        end
      end
      register_as
    end

    # GoToR — go to a destination in a remote document. §12.6.4.3
    class GoToR < Base
      class << self
        def action_type; :GoToR; end

        def to_pdf(file_spec:, dest:, new_window: nil)
          payload = { S: :GoToR, F: file_spec, D: dest }
          payload[:NewWindow] = new_window unless new_window.nil?
          payload
        end
      end
      register_as
    end

    # SubmitForm — submit form data to a URL. §12.7.6.2
    class SubmitForm < Base
      class << self
        def action_type; :SubmitForm; end

        def to_pdf(url:, flags: 0)
          { S: :SubmitForm, F: url, Flags: flags }
        end
      end
      register_as
    end

    # ResetForm — reset form fields to defaults. §12.7.6.3
    class ResetForm < Base
      class << self
        def action_type; :ResetForm; end

        def to_pdf(fields: nil, flags: 0)
          payload = { S: :ResetForm, Flags: flags }
          payload[:Fields] = fields if fields
          payload
        end
      end
      register_as
    end

    # JavaScript — execute JavaScript. §12.6.4.16
    # NOTE: PDF/A prohibits this; included for completeness.
    class JavaScript < Base
      class << self
        def action_type; :JavaScript; end

        def to_pdf(script:)
          { S: :JavaScript, JS: script }
        end
      end
      register_as
    end

    # Hide — show or hide an annotation. §12.6.4.9
    class Hide < Base
      class << self
        def action_type; :Hide; end

        def to_pdf(target:, hide: true)
          { S: :Hide, T: target, H: hide }
        end
      end
      register_as
    end

    # ImportData — import FDF/XFDF form data. §12.7.6.4
    class ImportData < Base
      class << self
        def action_type; :ImportData; end

        def to_pdf(file_spec:)
          { S: :ImportData, F: file_spec }
        end
      end
      register_as
    end

    # SetOCGState — toggle optional-content groups. §12.6.4.13
    class SetOCGState < Base
      class << self
        def action_type; :SetOCGState; end

        def to_pdf(state:, preserve_rb: false)
          payload = { S: :SetOCGState, State: state }
          payload[:PreserveRB] = preserve_rb unless preserve_rb == false
          payload
        end
      end
      register_as
    end

    # Trans — page transition for slide-show mode. §12.4.3
    class Trans < Base
      class << self
        def action_type; :Trans; end

        def to_pdf(style:, duration: nil, direction: nil)
          trans = { S: style }
          trans[:D] = duration if duration
          trans[:Di] = direction if direction
          { S: :Trans, Trans: trans }
        end
      end
      register_as
    end

    # GoToE — go to a destination in an embedded file. §12.6.4.4 (PDF 1.6+)
    class GoToE < Base
      class << self
        def action_type; :GoToE; end

        def to_pdf(file_spec:, dest:, new_window: nil)
          payload = { S: :GoToE, F: file_spec, D: dest }
          payload[:NewWindow] = new_window unless new_window.nil?
          payload
        end
      end
      register_as
    end
  end
end
