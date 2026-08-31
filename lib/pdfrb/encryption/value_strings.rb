# frozen_string_literal: true

module Pdfrb
  module Encryption
    # The COS value-tree string walk, shared by both directions of
    # the encryption seam: the Serializer encrypts every literal
    # string an indirect object carries (building transformed
    # copies), and the ObjectReader decrypts them back (mutating the
    # freshly-parsed containers in place). One walk, two adapters —
    # keeps the string set and traversal rules from drifting.
    module ValueStrings
      module_function

      # @return [Object] a transformed copy of +value+ with every
      #   literal string replaced by the block's result.
      def encrypt(value, oid, gen, cipher)
        case value
        when ::Hash
          value.each_with_object({}) { |(k, v), h| h[k] = encrypt(v, oid, gen, cipher) }
        when ::Array
          value.map { |v| encrypt(v, oid, gen, cipher) }
        when Pdfrb::Model::PdfArray
          Pdfrb::Model::PdfArray.new(value.map { |v| encrypt(v, oid, gen, cipher) })
        when Pdfrb::Model::Object
          Pdfrb::Model::Object.new(encrypt(value.value, oid, gen, cipher),
                                   oid: value.oid, gen: value.gen)
        when ::String
          bytes = if value.encoding == Encoding::UTF_8
                    Pdfrb::Model::Cos::StringEncoding.encode_text(value)
                  else
                    value.dup.force_encoding(Encoding::BINARY)
                  end
          cipher.encrypt_string(bytes, oid, gen)
        else
          value
        end
      end

      # Replaces every literal string inside the freshly-parsed
      # +value+ (a Hash/Array container tree) with its decrypted
      # form, in place. Returns +value+.
      def decrypt!(value, oid, gen, cipher)
        case value
        when ::Hash
          value.each { |k, v| value[k] = decrypt!(v, oid, gen, cipher) }
        when ::Array
          value.map! { |v| decrypt!(v, oid, gen, cipher) }
        when Pdfrb::Model::PdfArray
          value.value.map! { |v| decrypt!(v, oid, gen, cipher) }
          value
        when ::String
          cipher.decrypt_string(value, oid, gen)
        else
          value
        end
      end
    end
  end
end
