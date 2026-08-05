# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Embedded file stream (s7.11.3). The actual payload of a
      # /Filespec /EF entry.
      class EmbeddedFile < Pdfrb::Model::Cos::Stream
        arlington_object "EmbeddedFileStream"
        register_type :EmbeddedFile

        def subtype; self[:Subtype]; end
        def length; self[:Length]; end
        def filter; self[:Filter]; end
        def params; self[:Params]; end
        def checksum; self[:Params] && self[:Params][:CheckSum]; end
        def creation_date; self[:Params] && self[:Params][:CreationDate]; end
        def modification_date; self[:Params] && self[:Params][:ModDate]; end
        def size; self[:Params] && self[:Params][:Size]; end
        def mac_creator; self[:Params] && self[:Params][:Mac]; end

        def compressed?
          filter && !filter.to_s.empty?
        end

        def mime_type
          subtype&.to_s
        end
      end
    end
  end
end
