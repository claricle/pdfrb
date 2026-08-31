# frozen_string_literal: true

module Pdfrb
  module Encryption
    module Identity
      module_function

      def encrypt(data, **_opts); data; end
      def decrypt(data, **_opts); data; end
      def encrypt_string(data, *_); data; end
      def encrypt_stream(data, *_); data; end
      def decrypt_string(data, *_); data; end
      def decrypt_stream(data, *_); data; end
      def key_length; 0; end
    end
  end
end
