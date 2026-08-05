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
    end
  end
end
