# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # File-level helpers: FileSize.
        module FilePredicates
          module_function

          def register_all
            Functions.register("FileSize") do |_args, ctx|
              ctx.file_size
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::FilePredicates.register_all
