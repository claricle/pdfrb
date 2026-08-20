# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # Shared Arlington TSV binding for COS container classes.
      # Cos::Dictionary extends this and merges field definitions via
      # define_field; Model::PdfArray extends it and keeps the
      # positional definition for element-type lookup. Either way the
      # class is registered in Pdfrb::Model::Type.arlington_registry
      # so field-link resolution can find it.
      module ArlingtonBacked
        # Pull the named Arlington TSV. Idempotent. Silently no-ops
        # when the Arlington layer or the TSV is unavailable, so
        # hand-coded subclasses still work.
        def arlington_object(name, version: "latest")
          return if arlington_loaded_for?(name)
          return unless arlington_available?

          definition = Pdfrb::Arlington::Loader.object_definition(name, version: version)
          return unless definition

          arlington_mark_loaded(name)
          Pdfrb::Model::Type.register_arlington(name, self) if Pdfrb::Model.const_defined?(:Type)
          apply_arlington_definition(definition)
        end

        def arlington_loaded_for?(arlington_name)
          @arlington_loaded_name == arlington_name
        end
        private :arlington_loaded_for?

        def arlington_mark_loaded(name)
          @arlington_loaded_name = name
        end
        private :arlington_mark_loaded

        def arlington_available?
          Pdfrb.const_defined?(:Arlington) &&
            Pdfrb::Arlington.const_defined?(:Loader)
        rescue StandardError
          false
        end
        private :arlington_available?

        # Hook: containers override to consume the definition.
        def apply_arlington_definition(_definition); end
        private :apply_arlington_definition
      end
    end
  end
end
