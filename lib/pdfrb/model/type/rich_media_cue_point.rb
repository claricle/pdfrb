# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Cue Point (s13.6.6). Time marker in a media playback.
      class RichMediaCuePoint < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def time; self[:Time]; end
        def name; self[:Name]; end

        def has_time?
          !!time
        end
      end
    end
  end
end
