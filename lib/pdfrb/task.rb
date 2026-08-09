# frozen_string_literal: true

module Pdfrb
  module Task
    autoload :ExtractText, "pdfrb/task/extract_text"
    autoload :ExtractImages, "pdfrb/task/extract_images"
    autoload :Merge, "pdfrb/task/merge"
    autoload :Optimize, "pdfrb/task/optimize"
    autoload :GenerateCorpus, "pdfrb/task/generate_corpus"
    autoload :Benchmark, "pdfrb/task/benchmark"
    autoload :MemoryProfile, "pdfrb/task/memory_profile"
    autoload :RegenerateAppearances, "pdfrb/task/regenerate_appearances"
    autoload :Thumbnail, "pdfrb/task/thumbnail"
  end
end
