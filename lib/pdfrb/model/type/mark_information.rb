# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # MarkInformation (s14.7.1). Catalog /MarkInfo — flags whether
      # the document is tagged and structural metadata is reliable.
      class MarkInformation < Cos::Dictionary
        register_type :MarkInfo

        def type; self[:Type]; end

        def marked?; truthy?(self[:Marked]); end
        def user_properties?; truthy?(self[:UserProperties]); end
        def suspects?; truthy?(self[:Suspects]); end

        def tagged?
          marked? && !suspects?
        end
      end
    end
  end
end
