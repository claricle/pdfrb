# frozen_string_literal: true

module Pdfrb
  module Filter
    module DCTDecode
      module_function

      def decoder(data, **_opts)
        data
      end

      def encoder(data, **_opts)
        data
      end
    end
    REGISTRY[:DCTDecode] = DCTDecode if defined?(REGISTRY)
  end
end
