# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # URL Alias (s7.9.6). Names dictionary entry mapping friendly
      # URLs to actual URLs for collection sub-items.
      class URLAlias < Pdfrb::Model::Cos::Dictionary
        arlington_object "URLAlias"
        def type; self[:Type]; end
        def alias_value; self[:U]; end
        def url; self[:URL]; end

        def has_alias?
          !!alias_value
        end
      end
    end
  end
end
