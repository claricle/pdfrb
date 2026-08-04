# frozen_string_literal: true

module Pdfrb
  module Encryption
    module Identity
      module_function

      def encrypt(data, **_opts); data; end
      def decrypt(data, **_opts); data; end
      def key_length; 0; end
    end
  end
end
