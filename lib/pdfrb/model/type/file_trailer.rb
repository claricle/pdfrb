# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # File trailer dict (s7.5.5). Root of the cross-reference chain.
      # Fields: /Size, /Prev, /Root, /Encrypt, /Info, /ID, /XRefStm,
      # /AuthCode, /AdditionalStreams, /DocChecksum.
      class FileTrailer < Pdfrb::Model::Cos::Dictionary
        arlington_object "FileTrailer"
        register_type :FileTrailer

        def size; self[:Size]; end
        def prev; self[:Prev]; end
        def root; self[:Root]; end
        def encrypt; self[:Encrypt]; end
        def info; self[:Info]; end
        def id; self[:ID]; end
        def xref_stream_offset; self[:XRefStm]; end
        def doc_checksum; self[:DocChecksum]; end

        def encrypted?
          !!encrypt
        end

        def incremental?
          !!prev
        end

        def has_id?
          id && id.is_a?(Array) && id.size == 2
        end

        def original_id
          return nil unless has_id?
          arr = id.is_a?(Pdfrb::Model::PdfArray) ? id.to_a : id
          arr[0]
        end

        def current_id
          return nil unless has_id?
          arr = id.is_a?(Pdfrb::Model::PdfArray) ? id.to_a : id
          arr[1] || arr[0]
        end

        def resolved_root
          return nil unless root && document
          document.object(root)
        end

        def resolved_info
          return nil unless info && document
          document.object(info)
        end

        def resolved_encrypt
          return nil unless encrypt && document
          document.object(encrypt)
        end
      end
    end
  end
end
