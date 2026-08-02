# frozen_string_literal: true

module Pdfrb
  module Filter
    DCTDecode = Class.new do
      include Base
      register_as "DCTDecode"
      class << self
        def decoder(bytes, _parms, _document); bytes; end
        def encoder(bytes, _parms, _document); bytes; end
      end
    end.freeze
    public_constant :DCTDecode

    JPXDecode = Class.new do
      include Base
      register_as "JPXDecode"
      class << self
        def decoder(bytes, _parms, _document); bytes; end
        def encoder(bytes, _parms, _document); bytes; end
      end
    end.freeze
    public_constant :JPXDecode

    JBIG2Decode = Class.new do
      include Base
      register_as "JBIG2Decode"
      class << self
        def decoder(bytes, _parms, _document); bytes; end
        def encoder(bytes, _parms, _document); bytes; end
      end
    end.freeze
    public_constant :JBIG2Decode

    CCITTFaxDecode = Class.new do
      include Base
      register_as "CCITTFaxDecode"
      class << self
        def decoder(bytes, _parms, _document)
          raise Pdfrb::FilterError.new(
            "CCITTFaxDecode requires an external decoder (Group 3/4 fax)",
            filter_name: "CCITTFaxDecode"
          )
        end
        def encoder(_bytes, _parms, _document)
          raise Pdfrb::FilterError.new(
            "CCITTFaxDecode encoder not implemented",
            filter_name: "CCITTFaxDecode"
          )
        end
      end
    end.freeze
    public_constant :CCITTFaxDecode
  end
end
