# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Sound stream (s13.3). Sound effect annotation payload.
      # /R = sampling rate, /C = channels, /B = bits/sample, /E =
      # encoding (Raw, Signed, MuLaw, ALaw).
      class Sound < Pdfrb::Model::Cos::Stream
        arlington_object "SoundObject"
        def type; self[:Type]; end
        def sampling_rate; self[:R]; end
        def channels; self[:C] || 1; end
        def bits_per_sample; self[:B] || 8; end
        def encoding; self[:E]&.to_sym || :Raw; end

        def raw_encoding?; encoding == :Raw; end
        def signed_encoding?; encoding == :Signed; end
        def mu_law_encoding?; encoding == :MuLaw; end
        def a_law_encoding?; encoding == :ALaw; end

        def sample_bytes
          (channels * bits_per_sample) / 8.0
        end

        def duration_seconds
          return nil unless sampling_rate&.positive?

          bytes = stream ? stream.bytesize : 0
          bytes.to_f / (sample_bytes * sampling_rate)
        end

        def audio_data
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
