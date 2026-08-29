# frozen_string_literal: true

module Pdfrb
  class Document
    # Named-destinations facade. Manages both name-tree destinations
    # (Catalog /Names /Dests) and the explicit /Dests dictionary.
    class Destinations
      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Look up a named destination by name. Returns the destination
      # array or nil.
      def [](name)
        dests_dict = resolved_explicit_dict
        return dests_dict[name] if dests_dict && dests_dict[name]

        name_tree = resolved_name_tree
        lookup_in_name_tree(name_tree, name)
      end

      # Add an explicit destination under +name+. Creates the /Dests
      # dictionary if absent. +destination+ is typically an Array
      # [page_ref, fit_keyword, *args].
      def add(name, destination)
        ensure_dictionaries
        catalog = document.catalog
        catalog.value[:Dests] ||= {}
        catalog.value[:Dests][name.to_sym] = destination
        name.to_sym
      end

      # Enumerate all destination names (from both /Dests and /Names/Dests).
      def each_name(&)
        return enum_for(:each_name) unless block_given?

        seen = Set.new
        explicit = resolved_explicit_dict
        explicit&.each_key do |k|
          next if seen.include?(k)

          seen << k
          yield k
        end

        name_tree = resolved_name_tree
        each_name_tree_key(name_tree) do |k|
          next if seen.include?(k)

          seen << k
          yield k
        end
      end

      def names
        each_name.to_a
      end

      def empty?
        names.empty?
      end

      def count
        names.size
      end

      private

      def ensure_dictionaries
        catalog = document.catalog
        catalog.value[:Names] ||= {}
        catalog.value[:Names][:Dests] ||= {}
      end

      def resolved_explicit_dict
        catalog = document.catalog
        d = catalog.value[:Dests]
        return nil unless d

        document.resolve(d)
      end

      def resolved_name_tree
        catalog = document.catalog
        names = catalog.value[:Names]
        return nil unless names

        names = document.object(names) if names.is_a?(Pdfrb::Model::Reference)
        return nil unless names

        d = names.is_a?(Pdfrb::Model::Cos::Dictionary) ? names.value[:Dests] : names[:Dests]
        return nil unless d

        document.resolve(d)
      end

      def lookup_in_name_tree(node, name)
        return nil unless node

        if node.is_a?(Pdfrb::Model::Cos::Dictionary) && node.value[:Names]
          arr = node.value[:Names]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each_slice(2) { |k, v| return v if k == name }
        elsif node.is_a?(Pdfrb::Model::Cos::Dictionary) && node.value[:Kids]
          arr = node.value[:Kids]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each do |kid_ref|
            kid = document.resolve(kid_ref)
            result = lookup_in_name_tree(kid, name)
            return result if result
          end
        elsif node.is_a?(Hash) && node[:Names]
          arr = node[:Names]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each_slice(2) { |k, v| return v if k == name }
        end
        nil
      end

      def each_name_tree_key(node, &block)
        return unless node

        if node.is_a?(Pdfrb::Model::Cos::Dictionary) && node.value[:Names]
          arr = node.value[:Names]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each_slice(2) { |k, _v| yield k }
        elsif node.is_a?(Pdfrb::Model::Cos::Dictionary) && node.value[:Kids]
          arr = node.value[:Kids]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each do |kid_ref|
            kid = document.resolve(kid_ref)
            each_name_tree_key(kid, &block)
          end
        elsif node.is_a?(Hash) && node[:Names]
          arr = node[:Names]
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr.each_slice(2) { |k, _v| yield k }
        end
      end
    end
  end
end
