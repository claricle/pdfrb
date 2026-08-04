# frozen_string_literal: true

module Pdfrb
  module Filter
    module CCITTFaxDecode
      module_function

      def decoder(data, **_opts); data; end
      def encoder(data, **_opts); data; end
    end
  end
end
