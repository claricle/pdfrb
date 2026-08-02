# frozen_string_literal: true

module Pdfrb
  module Arlington
    module Predicate
      module Functions
        # Version predicates: SinceVersion, BeforeVersion, Deprecated,
        # IsPDFVersion, Extension.
        module VersionPredicates
          module_function

          def register_all
            Functions.register("SinceVersion") do |args, ctx|
              ver = args.first
              next false unless ver.is_a?(Pdfrb::Arlington::PdfVersion)

              ctx.version >= ver
            end

            Functions.register("BeforeVersion") do |args, ctx|
              ver = args.first
              next false unless ver.is_a?(Pdfrb::Arlington::PdfVersion)

              ctx.version < ver
            end

            Functions.register("Deprecated") do |args, ctx|
              ver = args.first
              next false unless ver.is_a?(Pdfrb::Arlington::PdfVersion)

              ctx.version >= ver
            end

            Functions.register("IsPDFVersion") do |args, ctx|
              ver = args.first
              next false unless ver.is_a?(Pdfrb::Arlington::PdfVersion)

              ctx.version == ver
            end

            Functions.register("Extension") do |_args, _ctx|
              # Whether a named extension applies is document-specific;
              # default false (consumer can override via Document config).
              false
            end
          end
        end
      end
    end
  end
end

Pdfrb::Arlington::Predicate::Functions::VersionPredicates.register_all
