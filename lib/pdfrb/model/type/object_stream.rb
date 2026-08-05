# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Compressed object stream (s7.5.7). /Type /ObjStm, /N count,
      # /First byte offset of first object, /Extends parent ObjStm.
      class ObjectStream < Pdfrb::Model::Cos::Stream
        arlington_object "ObjectStream"
        register_type :ObjStm

        def type; self[:Type]; end
        def number_of_objects; self[:N]; end
        def first_byte_offset; self[:First]; end
        def extends; self[:Extends]; end
        def filter; self[:Filter]; end

        def has_parent?
          !!extends
        end

        def compressed_count
          number_of_objects || 0
        end

        def each_object_reference
          return enum_for(:each_object_reference) unless block_given?
          return unless number_of_objects && first_byte_offset

          stream_data = decoded_stream
          return unless stream_data

          offset = 0
          number_of_objects.times do
            space_idx = stream_data.index(" ", offset)
            return if space_idx.nil?
            oid = stream_data[offset...space_idx].to_i

            newline_idx = stream_data.index(/\s/, space_idx + 1)
            return if newline_idx.nil?
            byte_offset = stream_data[space_idx + 1...newline_idx].to_i

            yield oid, byte_offset + first_byte_offset
            offset = newline_idx + 1
          end
        end
      end
    end
  end
end
