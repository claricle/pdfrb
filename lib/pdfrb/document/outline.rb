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

      def add(title, dest: nil, parent: nil)
        entry = OutlineEntry.new(title: title.to_s, dest: dest)
        if parent
          parent.add_child(entry)
        else
          @entries << entry
        end
        entry
      end

      def build!
        return if @entries.empty?

        root = @document.add(
          { Type: :Outlines },
          type: Pdfrb::Model::Cos::Dictionary
        )
        root_ref = root.ref

        prev_dict = nil
        first_ref = nil
        @entries.each do |entry|
          dict = entry.build!(@document)
          ref = dict.ref

          dict.value[:Parent] = root_ref
          dict.value[:Prev] = prev_dict.ref if prev_dict
          dict.value[:Next] = nil
          prev_dict&.value&.[]=(:Next, ref)

          first_ref ||= ref
          prev_dict = dict
        end

        root.value[:First] = first_ref
        root.value[:Last] = prev_dict.ref if prev_dict
        root.value[:Count] = @entries.length

        @document.catalog.value[:Outlines] = root_ref
        root
      end
    end

    class OutlineEntry
      attr_reader :title, :dest, :children

      def initialize(title:, dest:)
        @title = title
        @dest = dest
        @children = []
      end

      def add_child(entry)
        @children << entry
        entry
      end

      def build!(document)
        dict = document.add({ Title: @title }, type: Pdfrb::Model::Cos::Dictionary)
        dict.value[:Dest] = @dest if @dest

        if @children.any?
          prev_child_dict = nil
          first_ref = nil
          @children.each do |child|
            child_dict = child.build!(document)
            child_ref = child_dict.ref
            parent_ref = dict.ref

            child_dict.value[:Parent] = parent_ref
            child_dict.value[:Prev] = prev_child_dict.ref if prev_child_dict
            child_dict.value[:Next] = nil
            prev_child_dict&.value&.[]=(:Next, child_ref)

            first_ref ||= child_ref
            prev_child_dict = child_dict
          end

          dict.value[:First] = first_ref
          dict.value[:Last] = prev_child_dict.ref if prev_child_dict
          dict.value[:Count] = @children.length
        end

        dict
      end
    end
  end
end
