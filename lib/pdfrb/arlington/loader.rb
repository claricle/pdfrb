# frozen_string_literal: true

module Pdfrb
  module Arlington
    # Reads vendored Arlington TSVs from `data/pdfrb/arlington/<version>/`.
    # Parsed ObjectDefinitions are memoized per (name, version).
    #
    # Errors:
    #   * Pdfrb::Error if the TSV file is missing.
    #   * Pdfrb::ParseError if a row has the wrong column count.
    module Loader
      HEADER = %w[Key Type SinceVersion DeprecatedIn Required IndirectReference
                  Inheritable DefaultValue PossibleValues SpecialCase Link Note].freeze
      private_constant :HEADER

      @cache = {}

      class << self
        # Returns the ObjectDefinition for +name+ (e.g. "Catalog"),
        # reading and parsing the TSV the first time, then memoizing.
        def object_definition(name, version: "latest")
          cache_key = [version, name]
          return @cache[cache_key] if @cache.key?(cache_key)

          @cache[cache_key] = read_and_parse(name, version)
        end

        def clear_cache!
          @cache.clear
        end

        # Enumerate the names of every object defined in +version+
        # (without extensions). Useful for conformance sweeps.
        def list_object_names(version: "latest")
          dir = tsv_dir(version)
          return [] unless Dir.exist?(dir)

          Dir.children(dir).sort.filter_map do |f|
            f.sub(/\.tsv\z/, "") if f.end_with?(".tsv")
          end
        end

        private

        def read_and_parse(name, version)
          path = tsv_path(name, version)
          raise Pdfrb::Error, "Arlington TSV not found: #{name} (#{version})" unless File.exist?(path)

          rows = parse_tsv(File.binread(path))
          ObjectDefinition.from_tsv(rows, name: name, version: version)
        end

        def tsv_dir(version)
          File.join(Pdfrb::DataDir.root, "arlington", version)
        end

        def tsv_path(name, version)
          File.join(tsv_dir(version), "#{name}.tsv")
        end

        def parse_tsv(text)
          text.force_encoding(Encoding::UTF_8)
          lines = text.each_line.map { |l| l.chomp("\n").chomp("\r") }
          lines.shift # discard header row
          lines.filter_map do |line|
            next if line.strip.empty?

            cells = line.split("\t", -1)
            # Real-world TSVs occasionally drop trailing empty cells
            # (e.g. missing Note column). Pad to 12; reject if longer.
            if cells.length < 12
              cells.fill("", cells.length...12)
            elsif cells.length > 12
              raise Pdfrb::ParseError,
                    "Arlington row has #{cells.length} cells (expected 12): #{line.inspect}"
            end

            cells
          end
        end
      end
    end
  end
end
