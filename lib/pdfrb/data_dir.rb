# frozen_string_literal: true

module Pdfrb
  # Resolves the gem's bundled data directory (Arlington TSVs, AFM
  # metrics, default fonts, ICC profiles). Data lives under
  # data/pdfrb/ in the gem, which gem-install places on the load path
  # alongside lib/.
  module DataDir
    DELIMITER = "/"

    class << self
      # Absolute path to the gem's data root.
      def root
        File.expand_path("../../data/pdfrb", __dir__)
      end

      # Resolve a path inside the data root. Raises if the file does
      # not exist; this is a deployment error, not a user error.
      def resolve(*segments)
        path = File.join(root, *segments)
        unless File.exist?(path)
          raise Error, "missing data file: #{segments.join(DELIMITER)}"
        end

        path
      end

      # Path to the vendored Arlington TSV set for a given PDF version
      # (or "latest"). Versions live under data/pdfrb/arlington/.
      def arlington(version = "latest")
        File.join(root, "arlington", version)
      end
    end
  end
end
