# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Stream (s13.6.3). Carries a U3D or PRC binary 3D model.
      class ThreeDStream < Pdfrb::Model::Cos::Stream
        arlington_object "3DStream"
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def views; self[:VA]; end
        def default_view; self[:DV]; end
        def animation; self[:AN]; end
        def on_instantiate; self[:OnInstantiate]; end
        def color_space; self[:ColorSpace]; end

        def u3d?
          subtype == :U3D
        end

        def prc?
          subtype == :PRC
        end

        def step?
          subtype == :STEP
        end

        def view_count
          return 0 unless views

          arr = views.is_a?(Pdfrb::Model::PdfArray) ? views.to_a : views
          arr.is_a?(Array) ? arr.size : 0
        end

        def each_view
          return enum_for(:each_view) unless block_given?
          return unless views && document

          arr = views.is_a?(Pdfrb::Model::PdfArray) ? views.to_a : views
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end
    end
  end
end
