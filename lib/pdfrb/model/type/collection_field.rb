# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection field (s7.11.5). One column definition.
      class CollectionField < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionField"
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
    end
  end
end
