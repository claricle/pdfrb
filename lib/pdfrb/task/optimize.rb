# frozen_string_literal: true

module Pdfrb
  module Task
    # Placeholder for the optimise task. Real implementation needs
    # TODO 31 (object-stream packing) + dedup hash + xref-stream
    # conversion. For now: no-op pass-through so the CLI can wire
    # without raising.
    module Optimize
      module_function

      def call(document, **_opts)
        # TODO: dedup, pack into ObjStm, switch to xref stream.
        document
      end
    end
  end
end
