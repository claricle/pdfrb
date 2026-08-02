# frozen_string_literal: true

module Pdfrb
  module Filter
    # Common interface for stream filters. Subclasses must implement
    # `decoder(bytes, parms, document)` and `encoder(bytes, parms,
    # document)` class methods, and call `register_as` at the bottom
    # of the file.
    module Base
      class << self
        def included(host)
          host.extend(ClassMethods)
        end
      end

      module ClassMethods
        # Register this class under +name+ in Pdfrb::Filter.registry.
        def register_as(name)
          Pdfrb::Filter.register(name, self)
        end

        def decoder(_bytes, _parms, _document)
          raise NotImplementedError, "#{name}.decoder not implemented"
        end

        def encoder(_bytes, _parms, _document)
          raise NotImplementedError, "#{name}.encoder not implemented"
        end
      end
    end
  end
end
