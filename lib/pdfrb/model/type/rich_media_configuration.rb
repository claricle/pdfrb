# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Configuration (s13.6.2). A media instance list.
      class RichMediaConfiguration < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaConfiguration"
        def type; self[:Type]; end
        def instances; self[:Instances]; end
        def name; self[:Name]; end

        def instance_count
          return 0 unless instances

          arr = instances.is_a?(Pdfrb::Model::PdfArray) ? instances.to_a : instances
          arr.is_a?(Array) ? arr.size : 0
        end

        def each_instance
          return enum_for(:each_instance) unless block_given?
          return unless instances && document

          arr = instances.is_a?(Pdfrb::Model::PdfArray) ? instances.to_a : instances
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end
    end
  end
end
