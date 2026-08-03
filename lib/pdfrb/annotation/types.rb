# frozen_string_literal: true

module Pdfrb
  module Annotation
    # Concrete annotation types (ISO 32000-2 §12.5.6). Each class
    # defines its /Subtype and type-specific defaults, then registers
    # itself via +register_as+.
    #
    # OCP: new annotation type = new class + register_as. No edits
    # to existing code.

    # Text annotation (sticky note). §12.5.6.4
    class Text < Base
      class << self
        def subtype; :Text; end

        def default_fields
          { Name: :Comment }
        end
      end
      register_as
    end

    # Link annotation (hyperlink). §12.5.6.5
    class Link < Base
      class << self
        def subtype; :Link; end

        def default_fields
          { H: :I } # Invert highlight by default
        end
      end
      register_as
    end

    # FreeText annotation (free-form text box). §12.5.6.6
    class FreeText < Base
      class << self
        def subtype; :FreeText; end

        def default_fields
          { DA: "/Helv 0 Tf 0 g" }
        end
      end
      register_as
    end

    # Stamp annotation (rubber stamp). §12.5.6.8
    class Stamp < Base
      class << self
        def subtype; :Stamp; end

        def default_fields
          { Name: :Draft }
        end
      end
      register_as
    end

    # Popup annotation. §12.5.6.13. Usually paired with a markup annot
    # via the markup's /Popup key.
    class Popup < Base
      class << self
        def subtype; :Popup; end

        def default_fields
          { Open: false }
        end
      end
      register_as
    end

    # FileAttachment annotation (embedded file). §12.5.6.15
    # Inspired by mn2pdf's FileAttachmentAnnotation.
    class FileAttachment < Base
      class << self
        def subtype; :FileAttachment; end

        def default_fields
          { Name: :PushPin }
        end
      end
      register_as
    end

    # Highlight (text markup). §12.5.6.10
    class Highlight < Base
      class << self
        def subtype; :Highlight; end
      end
      register_as
    end

    # Underline (text markup). §12.5.6.10
    class Underline < Base
      class << self
        def subtype; :Underline; end
      end
      register_as
    end

    # Squiggly (text markup). §12.5.6.10
    class Squiggly < Base
      class << self
        def subtype; :Squiggly; end
      end
      register_as
    end

    # StrikeOut (text markup). §12.5.6.10
    class StrikeOut < Base
      class << self
        def subtype; :StrikeOut; end
      end
      register_as
    end

    # Square (shape markup). §12.5.6.8
    class Square < Base
      class << self
        def subtype; :Square; end
      end
      register_as
    end

    # Circle (shape markup). §12.5.6.8
    class Circle < Base
      class << self
        def subtype; :Circle; end
      end
      register_as
    end
  end
end
