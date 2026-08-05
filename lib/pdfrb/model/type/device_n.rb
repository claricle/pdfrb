# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DeviceN color space (s8.6.6.4). Multiple custom colorants mapped
      # through a single tint-transform function. Generalises Separation.
      class DeviceN < Pdfrb::Model::Cos::Dictionary
        def colorants; self[:Names]; end
        def alternate_space; self[:AlternateSpace]; end
        def tint_transform; self[:TintTransform]; end
        def attributes; self[:Attributes]; end

        def colorant_count
          return 0 unless colorants

          arr = colorants.is_a?(Pdfrb::Model::PdfArray) ? colorants.to_a : colorants
          arr.is_a?(Array) ? arr.size : 0
        end

        def components
          colorant_count
        end

        def each_colorant(&)
          return enum_for(:each_colorant) unless block_given?
          return unless colorants

          arr = colorants.is_a?(Pdfrb::Model::PdfArray) ? colorants.to_a : colorants
          return unless arr.is_a?(Array)

          arr.each(&)
        end
      end
    end
  end
end
