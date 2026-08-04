# frozen_string_literal: true

module Pdfrb
  module Filter
    module JPXDecode
      module_function

      def decoder(data, **_opts)
        data
      end

      def encoder(data, **_opts)
        data
      end
    end
    REGISTRY[:JPXDecode] = JPXDecode if defined?(REGISTRY)
  end
end
