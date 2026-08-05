# frozen_string_literal: true

module Pdfrb
  # Font file resolver. Searches system font directories for font files
  # by family name + style. Eliminates the need for external font-finding
  # libraries like fontisan.
  class FontResolver
    DEFAULT_SEARCH_PATHS = [
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "/usr/share/fonts",
      File.expand_path("~/.local/share/fonts"),
      "/usr/local/share/fonts",
    ].freeze

    FontInfo = Struct.new(:path, :family, :style, :ps_name, keyword_init: true)

    attr_reader :search_paths, :cache

    def initialize(search_paths: DEFAULT_SEARCH_PATHS)
      @search_paths = search_paths.dup
      @cache = nil
    end

    def find(family:, style: "Regular")
      build_cache unless @cache
      normalized_family = family.downcase.gsub(/\s+/, "")
      normalized_style = style.downcase.gsub(/\s+/, "")

      @cache.each do |info|
        next unless info.family&.downcase&.gsub(/\s+/, "") == normalized_family
        next unless match_style?(info.style, normalized_style)

        return info.path
      end
      nil
    end

    def find_by_ps_name(ps_name)
      build_cache unless @cache
      normalized = ps_name.downcase

      @cache.each do |info|
        return info.path if info.ps_name&.downcase == normalized
      end
      nil
    end

    def available_fonts
      build_cache unless @cache
      @cache.dup
    end

    private

    def match_style?(actual, requested)
      return true if requested == "regular" && (actual.nil? || actual == "" || actual.downcase == "regular")
      return true if actual&.downcase&.gsub(/\s+/, "") == requested

      false
    end

    def build_cache
      @cache = []
      @search_paths.each do |dir|
        next unless Dir.exist?(dir)

        Dir.glob("**/*.{ttf,otf,ttc}", base: dir).each do |rel_path|
          full_path = File.join(dir, rel_path)
          info = parse_font_info(full_path)
          @cache << info if info
        end
      end
      @cache.freeze
    end

    def parse_font_info(path)
      data = File.binread(path)
      return nil unless valid_font_magic?(data)

      ttf = Pdfrb::Font::TrueType::File.new(data)
      name_table = ttf.name_table
      return FontInfo.new(path: path) unless name_table

      records = parse_name_table(name_table)
      family = records[1] || records[16]
      subfamily = records[2] || records[17]
      ps_name = records[6]

      FontInfo.new(path: path, family: family, style: subfamily, ps_name: ps_name)
    rescue StandardError
      FontInfo.new(path: path)
    end

    def valid_font_magic?(data)
      return false if data.bytesize < 4

      magic = data.byteslice(0, 4)
      return true if magic == "ttcf".b
      return true if magic == "\x00\x01\x00\x00".b
      return true if magic == "OTTO".b
      return true if magic == "true".b
      return true if magic == "typ1".b

      false
    end

    def parse_name_table(name_data)
      results = {}
      return results unless name_data && name_data.bytesize >= 6

      name_data.unpack1("n")
      count = name_data.unpack1("n", offset: 2)
      string_offset = name_data.unpack1("n", offset: 4)

      count.times do |i|
        offset = 6 + (i * 12)
        break if offset + 12 > name_data.bytesize

        platform_id, _encoding_id, _lang_id, name_id, length, str_offset =
          name_data.unpack("nnnnnn", offset: offset)
        next unless [1, 3].include?(platform_id)

        raw = name_data.byteslice(string_offset + str_offset, length)
        next unless raw

        str = if platform_id == 3
                raw.unpack("n*").pack("U*")
              else
                raw.force_encoding("UTF-8")
              end
        results[name_id] = str
      end
      results
    end
  end
end
