# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Media Clip Data stream (s13.3.3). Carries actual media payload.
      class MediaClip < Pdfrb::Model::Cos::Stream
        arlington_object "MediaClipData"
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

      # Media Clip Data MH/BE sub-dictionary (s13.3.3): /BU alternate
      # file-by-URL used when the primary fails.
      class MediaClipDataMHBE < Pdfrb::Model::Cos::Dictionary
        arlington_object "MediaClipDataMHBE"

        def alternate_url; self[:BU]; end
      end

      # Media Clip Section stream (s13.3.4): a temporal sub-section
      # of a MediaClipData.
      class MediaClipSection < Pdfrb::Model::Cos::Stream
        arlington_object "MediaClipSection"

        def subtype; self[:S]&.to_sym; end
        def name; self[:N]; end
        def duration; self[:D]; end
        def alternates; self[:Alt]; end
        def must_honor; self[:MH]; end
        def best_effort; self[:BE]; end
      end

      # Section MH/BE sub-dictionary (s13.3.4): begin/end times.
      class MediaClipSectionMHBE < Pdfrb::Model::Cos::Dictionary
        arlington_object "MediaClipSectionMHBE"

        def begin; self[:B]; end
        def ends; self[:E]; end
      end

      # Media duration (s13.3.2): /T time value in seconds.
      class MediaDuration < Pdfrb::Model::Cos::Dictionary
        arlington_object "MediaDuration"

        def seconds; self[:T]; end
      end

      # Media permissions (s13.3.2, Temp-File TF flags): validity
      # after saving, printing, and extraction.
      class MediaPermissions < Pdfrb::Model::Cos::Dictionary
        arlington_object "MediaPermissions"

        def temp_file_flags; self[:TF]; end

        # Bit 1: media invalid after saving.
        def invalid_after_save?; !temp_file_flags.nil? && temp_file_flags.nobits?(1); end

        # Bit 2: media invalid after printing.
        def invalid_after_print?; !temp_file_flags.nil? && temp_file_flags.nobits?(2); end
      end
    end
  end
end
