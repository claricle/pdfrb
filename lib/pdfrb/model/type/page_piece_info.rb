# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Page-piece dictionary (s14.5). Per-page metadata recording
      # application-specific private data. The dictionary hangs off
      # a page's /PieceInfo key and is keyed by application name;
      # each value carries /LastModified, /Private, and (optionally)
      # an /ASFStream reference for a stream-encoded private payload.
      #
      # Conforming readers MUST NOT interpret application-private
      # data; it survives round-trips and incremental updates intact.
      class PagePieceInfo < Pdfrb::Model::Cos::Dictionary
        # The application-name key (e.g. :Adobe, :Pdfrb). Multiple
        # applications may each have their own entry in the same
        # /PieceInfo dict.
        def application_name
          value.key?(:Application) ? value[:Application] : nil
        end

        # /LastModified — PDF date string, parsed to a Time.
        def last_modified
          v = value[:LastModified]
          return nil unless v.is_a?(::String)

          Pdfrb::Model::Date.parse(v)
        end

        # /Private — application-private dict. Untyped on purpose:
        # the contents are app-defined.
        def private_data
          value[:Private]
        end

        # Set the application's /LastModified to +time+. +time+ is
        # converted to a PDF date string.
        def last_modified=(time)
          value[:LastModified] = Pdfrb::Model::Date.format(time)
        end

        # Merge +hash+ into /Private. If /Private is absent, it is
        # created from the hash.
        def merge_private!(hash)
          existing = value[:Private]
          if existing.is_a?(Pdfrb::Model::Cos::Dictionary)
            existing.value.merge!(hash)
          elsif existing.is_a?(::Hash)
            existing.merge!(hash)
          else
            value[:Private] = hash
          end
          self
        end
      end
    end
  end
end
