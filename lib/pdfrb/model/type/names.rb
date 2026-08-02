# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Names dictionary (s7.9.6) — top-level name-tree roots for
      # /Dests, /AP, /JavaScript, /Pages, /Templates, /URLS,
      # /EmbeddedFiles, /AlternatePresentations, /Renditions.
      class Names < Pdfrb::Model::Cos::Dictionary
        arlington_object "Name"
      end
    end
  end
end
