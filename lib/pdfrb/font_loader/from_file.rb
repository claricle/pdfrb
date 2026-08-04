# frozen_string_literal: true

module Pdfrb
  module FontLoader
    module FromFile
      module_function

      def call(document, path, **_opts)
        return nil unless path.is_a?(String) && File.file?(path)

        data = File.binread(path)
        magic = data&.byteslice(0, 4)
        return nil unless magic
        return nil unless ["\x00\x01\x00\x00".b, "true".b, "OTTO".b].include?(magic)

        Pdfrb::Font::TrueType::Wrapper.embed(document, data, resource_name: :F1)
      end
    end
  end
end
