# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Media Clip Data stream (s13.3.3). Carries actual media payload.
      class MediaClip < Pdfrb::Model::Cos::Stream
        def type; self[:Type]; end
        def subtype; self[:S]&.to_sym; end

        def must_use_honest?
          subtype == :MIMEType
        end

        def file_spec; self[:D]; end
        def mime_type; self[:CT]; end
        def data_size; self[:S]; end

        def resolved_file_spec
          ref = file_spec
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
