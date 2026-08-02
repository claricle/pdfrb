# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      # Runtime context for predicate evaluation. Carries the current
      # object, the document version, the byte size of the source
      # file, and references to the parent and trailer dictionaries
      # for path expressions (`parent::Foo`, `trailer::Catalog`).
      class Context
        attr_reader :current, :version, :file_size, :parent, :trailer

        def initialize(current:, version:, file_size: 0, parent: nil, trailer: nil)
          @current = current
          @version = version
          @file_size = file_size.to_i
          @parent = parent
          @trailer = trailer
          freeze
        end
      end
    end
  end
end
