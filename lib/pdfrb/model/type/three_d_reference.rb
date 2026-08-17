# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Reference (s13.6.5). Indirect reference to a 3D stream
      # elsewhere in the document.
      class ThreeDReference < Pdfrb::Model::Cos::Dictionary
        arlington_object "3DReference"
        def type; self[:Type]; end
        def target_stream; self[:Target]; end

        def resolved_target
          ref = target_stream
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
