# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DeviceN attributes dictionary (s8.6.6.4, the 5th element of
      # the DeviceN color space array). Names extra colorants and
      # process/mixing hints.
      class DeviceN < Pdfrb::Model::Cos::Dictionary
        arlington_object "DeviceNDict"
        def subtype; self[:Subtype]&.to_sym; end
        def colorants; self[:Colorants]; end
        def process; self[:Process]; end
        def mixing_hints; self[:MixingHints]; end

        def nchannel?
          subtype == :NChannel
        end

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
