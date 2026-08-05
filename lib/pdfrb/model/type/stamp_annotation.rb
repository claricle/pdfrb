# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rubber-stamp annotation (s12.5.6.14).
      class StampAnnotation < MarkupAnnotation
        def name; self[:Name]; end
        def interior_color; self[:IC]; end
        def rotation; self[:Rotate] || 0; end
        def intent; self[:IT]; end

        def rubber_stamp?
          intent.nil? || intent&.to_sym == :Stamp
        end
      end
    end
  end
end
