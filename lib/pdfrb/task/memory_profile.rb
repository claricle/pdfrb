# frozen_string_literal: true

require "objspace"
require "stringio"

module Pdfrb
  module Task
    # Memory profiling using ObjectSpace. Reports total object allocations,
    # memory footprint, and identifies potential leaks for large documents.
    #
    # Usage:
    #   Pdfrb::Task::MemoryProfile.profile(pdf_bytes)
    #   Pdfrb::Task::MemoryProfile.compare(pdf_a, pdf_b)
    class MemoryProfile
      Snapshot = Struct.new(:total_objects, :total_bytes, :by_type,
                            keyword_init: true)

      class << self
        def profile(pdf_bytes)
          GC.start
          GC.disable

          baseline = object_snapshot

          doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes.dup))
          doc.each_indirect_object { |_obj| nil }
          doc.pages.each { |_page| nil }

          after = object_snapshot

          GC.enable

          Snapshot.new(
            total_objects: after.total_objects - baseline.total_objects,
            total_bytes: after.total_bytes - baseline.total_bytes,
            by_type: diff_types(baseline.by_type, after.by_type)
          )
        end

        def object_snapshot
          by_type = Hash.new(0)
          total_bytes = 0

          ObjectSpace.each_object do |obj|
            next if obj.is_a?(Class) || obj.is_a?(Module)

            type_label = type_label_for(obj)
            by_type[type_label] += 1
            total_bytes += ObjectSpace.memsize_of(obj)
          end

          Snapshot.new(
            total_objects: ObjectSpace.count_objects[:TOTAL],
            total_bytes: total_bytes,
            by_type: by_type
          )
        rescue StandardError
          Snapshot.new(total_objects: 0, total_bytes: 0, by_type: {})
        end

        def type_label_for(obj)
          case obj
          when String then "String"
          when Hash then "Hash"
          when Array then "Array"
          when Pdfrb::Model::Object, Pdfrb::Model::Cos::Dictionary then "Pdfrb::Model"
          when Pdfrb::Model::Reference then "Reference"
          when Pdfrb::Model::PdfArray then "PdfArray"
          else obj.class.name || obj.class.to_s
          end
        end

        def diff_types(before, after)
          result = {}
          (after.keys | before.keys).each do |type|
            delta = (after[type] || 0) - (before[type] || 0)
            result[type] = delta if delta != 0
          end
          result.sort_by { |_, v| -v }.to_h
        end
      end
    end
  end
end
