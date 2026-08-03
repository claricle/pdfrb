# frozen_string literal: true

module Pdfrb
  module Content
    module Operator
      # Clipping path operators (s8.5.4). W and W* modify the current
      # clipping path by intersecting it with the current path. The
      # clipping path takes effect when the next painting operator or
      # `n` (end path) is executed.

      # `W` — modify clipping path using nonzero winding rule.
      class ClipNonZero < NoArg
        def self.name; "W"; end
        register
      end

      # `W*` — modify clipping path using even-odd rule.
      class ClipEvenOdd < NoArg
        def self.name; "W*"; end
        register
      end

      # `Do` — invoke an XObject (Image or Form) by resource name.
      class InvokeXObject < Base
        class << self
          def name; "Do"; end

          def serialize(_serializer, name)
            "/#{name} Do\n"
          end
        end
        register
      end
    end
  end
end
