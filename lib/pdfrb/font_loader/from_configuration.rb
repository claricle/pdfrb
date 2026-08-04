# frozen_string_literal: true

module Pdfrb
  module FontLoader
    module FromConfiguration
      module_function

      def call(document, name, **_opts)
        config = document.config["font.#{name}"]
        return nil unless config

        case config["type"]
        when "standard14" then Standard14.call(document, config["name"] || name)
        when "file" then FromFile.call(document, config["path"])
        end
      end
    end
  end
end
