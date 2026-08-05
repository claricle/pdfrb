# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection dictionary (s7.11.5). Describes a PDF Portfolio — a
      # collection of embedded files with a presentation schema. Lives
      # on Catalog /Collection.
      class Collection < Pdfrb::Model::Cos::Dictionary
        def schema; self[:Schema]; end
        def default_view; self[:View]; end
        def sort; self[:Sort]; end
        def split; self[:Split]; end
        def colors; self[:Colors]; end
        def folders; self[:Folders]; end

        def has_schema?
          !!schema
        end

        def has_default_view?
          !!default_view
        end
      end

      # Collection schema (s7.11.5). Defines the columns/fields shown
      # in the portfolio view.
      class CollectionSchema < Pdfrb::Model::Cos::Dictionary
        def fields
          value.keys
        end

        def field_count
          value.size
        end

        def each_field(&)
          return enum_for(:each_field) unless block_given?

          value.each(&)
        end
      end

      # Collection sort (s711.5). Defines default sort order.
      class CollectionSort < Pdfrb::Model::Cos::Dictionary
        def field_name; self[:S]; end
        def descending?; truthy?(self[:A]); end
      end

      # Collection field (s7.11.5). One column definition.
      class CollectionField < Pdfrb::Model::Cos::Dictionary
        def name; self[:N]; end
        def field_type; self[:Subtype]; end
        def order; self[:O]; end
        def visibility; self[:V]; end

        def text_field?; field_type == :Text; end
        def number_field?; field_type == :Number; end
        def date_field?; field_type == :Date; end
        def file_name_field?; field_type == :FileName; end
        def file_size_field?; field_type == :FileSize; end
        def description_field?; field_type == :Desc; end
        def modification_date_field?; field_type == :ModDate; end
        def creation_date_field?; field_type == :CreationDate; end
      end

      # Collection item (s7.11.5). Per-embedded-file values for the
      # schema fields.
      class CollectionItem < Pdfrb::Model::Cos::Dictionary
        def value_for(field_name)
          self[field_name.to_sym] || self[field_name.to_s]
        end

        def keys
          value.keys
        end
      end
    end
  end
end
