# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # ICCBased Color Space (s8.6.5.5). Wrapper for the
      # [/ICCBased <stream-ref>] array form.
      class ICCBasedColorSpace < Pdfrb::Model::Cos::Stream
        def component_count; self[:N]; end
        def alternate; self[:Alternate]; end
        def range; self[:Range]; end
        def metadata_stream; self[:Metadata]; end

        def has_alternate?
          !!alternate
        end

        def has_metadata?
          !!metadata_stream
        end
      end
    end
  end
end
