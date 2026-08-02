# frozen_string_literal: true

module Pdfrb
  class Document
    # Bookmark/outline facade. Builds the /Outlines tree on the
    # Catalog so PDF viewers show a navigation panel.
    class Outline
      attr_reader :document, :entries

      def initialize(document)
        @document = document
        @entries = []
      end

      # Add a top-level bookmark entry.
      #
      # @param title [String] display text.
      # @param dest [Pdfrb::Model::Reference, Array, nil] destination
      #   (page reference or explicit destination array).
      # @param parent [OutlineEntry, nil] for nested entries.
      # @return [OutlineEntry]
      def add(title, dest: nil, parent: nil)
        entry = OutlineEntry.new(
          title: title.to_s,
          dest: dest,
          document: @document
        )
        if parent
          parent.add_child(entry)
        else
          @entries << entry
        end
        entry
      end

      def build!
        return if @entries.empty?

        entries = @entries
        root = @document.add(
          { Type: :Outlines, First: nil, Last: nil, Count: entries.length },
          type: Pdfrb::Model::Cos::Dictionary
        )

        prev_ref = nil
        first_ref = nil
        entries.each_with_index do |entry, _i|
          ref = entry.build!(@document)
          entry.value[:Parent] = Pdfrb::Model::Reference.new(root.oid, root.gen)
          entry.value[:Prev] = prev_ref if prev_ref
          entry.value[:Next] = nil
          prev_ref&.value&.[]=(:Next, ref)
          first_ref ||= ref
          prev_ref = ref
        end

        root.value[:First] = first_ref
        root.value[:Last] = prev_ref

        @document.catalog.value[:Outlines] =
          Pdfrb::Model::Reference.new(root.oid, root.gen)

        root
      end
    end

    class OutlineEntry
      attr_reader :title, :dest, :children, :value
      attr_accessor :oid

      def initialize(title:, dest:, document:)
        @title = title
        @dest = dest
        @document = document
        @children = []
        @value = {}
        @oid = nil
      end

      def add_child(entry)
        @children << entry
        entry
      end

      def build!(document)
        dict = document.add(
          {
            Title: @title,
            Parent: nil,
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        dict.value[:Dest] = @dest if @dest

        @oid = dict.oid
        @value = dict.value

        if @children.any?
          first_child = nil
          prev_child = nil
          @children.each do |child|
            child_ref = child.build!(document)
            child.value[:Parent] =
              Pdfrb::Model::Reference.new(dict.oid, dict.gen)
            child.value[:Prev] = prev_child.value ? Pdfrb::Model::Reference.new(prev_child.oid, 0) : nil if prev_child
            prev_child&.value&.[]=(:Next, Pdfrb::Model::Reference.new(child_ref.oid, 0))
            first_child ||= child_ref
            prev_child = child
          end
          dict.value[:First] = Pdfrb::Model::Reference.new(first_child.oid, 0)
          dict.value[:Last] = Pdfrb::Model::Reference.new(prev_child.oid, 0)
          dict.value[:Count] = @children.length
        end

        dict
      end
    end
  end
end
