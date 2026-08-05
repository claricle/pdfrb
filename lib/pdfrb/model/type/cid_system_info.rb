# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CIDSystemInfo dictionary (s9.7.3). Each CIDFont must declare
      # its Character ID system: registry, ordering, supplement.
      # Required for proper glyph interpretation.
      class CIDSystemInfo < Pdfrb::Model::Cos::Dictionary
        def registry; self[:Registry]; end
        def ordering; self[:Ordering]; end
        def supplement; self[:Supplement]; end

        def identity?
          registry == "Adobe" && ordering == "Identity"
        end

        def complete?
          !registry.nil? && !ordering.nil? && !supplement.nil?
        end

        def to_s
          "#{registry}-#{ordering}-#{supplement}"
        end
      end
    end
  end
end
