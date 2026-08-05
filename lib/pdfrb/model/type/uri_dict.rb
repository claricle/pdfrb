# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # URI dict (s12.5.6.5). Catalog /URI dict for base URI and
      # retriever map.
      class URIDict < Pdfrb::Model::Cos::Dictionary
        def base; self[:Base]; end
        def retriever_map; self[:Map]; end

        def has_base?
          !!base
        end
      end
    end
  end
end
