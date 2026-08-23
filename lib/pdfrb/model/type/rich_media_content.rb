# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Content (s13.6.5). Top-level rich media assets bundle.
      class RichMediaContent < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaContent"
        def type; self[:Type]; end
        def configurations; self[:Configurations]; end
        def assets; self[:Assets]; end

        def configuration_count
          return 0 unless configurations

          arr = configurations.is_a?(Pdfrb::Model::PdfArray) ? configurations.to_a : configurations
          arr.is_a?(Array) ? arr.size : 0
        end

        def asset_count
          return 0 unless assets

          obj = assets.is_a?(Pdfrb::Model::Reference) && document ? document.object(assets) : assets
          obj.is_a?(Pdfrb::Model::Cos::Dictionary) ? obj.value.size : 0
        end
      end
    end
  end
end
