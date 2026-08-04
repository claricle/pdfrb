# frozen_string_literal: true

module Pdfrb
  module Filter
    module JBIG2Decode
      module_function

      def decoder(data, **_opts); data; end
      def encoder(data, **_opts); data; end
    end
  end
end
