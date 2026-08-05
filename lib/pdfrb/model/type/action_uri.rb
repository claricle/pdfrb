# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # URI action (s12.6.4.7). Opens a URL in the browser.
      class ActionURI < Action
        register_subtype :URI

        def uri; self[:URI]; end
        def track_mouse?; self[:IsMap] == true; end

        def scheme
          return nil unless uri

          match = uri.to_s.match(%r{^([a-zA-Z][a-zA-Z0-9+.-]*):})
          match && match[1].downcase
        end

        def http?
          ["http", "https"].include?(scheme)
        end

        def mailto?
          scheme == "mailto"
        end
      end
    end
  end
end
