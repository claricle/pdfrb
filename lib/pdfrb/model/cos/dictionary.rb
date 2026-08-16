# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # Common Object Syntax dictionary (s7.3.7). Wraps a Hash of
      # Symbol -> PDF value. Subclassed by every semantic Type::*.
      #
      # Field metadata can come from two sources (mutually exclusive
      # per field; last declaration wins):
      #   * `define_field` — hand-coded (HexaPDF shape).
      #   * `arlington_object "Name"` — auto-loaded from vendored TSVs
      #     via Pdfrb::Arlington::Loader. Calls `define_field` under
      #     the hood with types translated to Ruby classes.
      class Dictionary < Pdfrb::Model::Object
        # ---- Per-class field registry ----

        # Shared type registry (s7.7 /Type symbol -> Dictionary
        # subclass). Lives on the Dictionary class itself, NOT on
        # subclasses, so register_type from any subclass lands in the
        # same map.
        TYPE_MAP = {}
        private_constant :TYPE_MAP

        class << self
          # /Type-symbol -> Dictionary subclass. Populated by
          # `register_type`. Used by Document#wrap to dispatch.
          def type_map
            TYPE_MAP
          end

          def register_type(symbol, klass = self)
            TYPE_MAP[symbol] = klass
            klass.define_type(symbol) unless klass.pdf_type
          end

          def lookup_type(symbol)
            TYPE_MAP[symbol]
          end

          # Declare a field on this class. Mirrors HexaPDF's
          # define_field shape; we add an `arlington:` slot for the
          # source FieldDefinition.
          def define_field(pdf_name, type:, required: false, default: nil,
                           indirect: nil, allowed_values: nil, version: "1.0",
                           arlington: nil)
            own_fields[pdf_name] = Fields::Field.new(
              pdf_name, type: type, required: required, default: default,
              indirect: indirect, allowed_values: allowed_values,
              version: version, arlington: arlington
            )
          end

          # Look up a field by name; walks the inheritance chain.
          def field(name)
            return own_fields[name] if own_fields.key?(name)
            return superclass.field(name) if superclass <= Pdfrb::Model::Cos::Dictionary

            nil
          end

          # Iterate (name, Field) pairs across the inheritance chain.
          def each_field
            return enum_for(:each_field) unless block_given?

            if superclass <= Pdfrb::Model::Cos::Dictionary
              superclass.each_field { |n, f| yield n, f }
            end
            own_fields.each { |n, f| yield n, f }
          end

          # Pull field metadata from the named Arlington TSV. Idempotent.
          # Silently no-ops when the Arlington layer or the TSV is
          # unavailable, so hand-coded subclasses still work.
          #
          # Also registers +self+ in Pdfrb::Model::Type.arlington_registry
          # under +name+ so field-link resolution can find this class
          # when other Types reference it.
          def arlington_object(name, version: "latest")
            return if arlington_loaded_for?(name)
            return unless arlington_available?

            definition = Pdfrb::Arlington::Loader.object_definition(name, version: version)
            return unless definition

            arlington_mark_loaded(name)
            Pdfrb::Model::Type.register_arlington(name, self) if Pdfrb::Model.const_defined?(:Type)
            definition.each_field do |field_def|
              define_field_from_arlington(field_def)
            end
          end

          def own_fields
            @own_fields ||= {}
          end
          private :own_fields

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

          # Merge Arlington field metadata with any hand-coded
          # define_field declaration. Hand-coded fields win: if the
          # class already declares this key explicitly (with a type),
          # we rebuild the Field preserving the hand-coded
          # type/default/required and only attach the Arlington def
          # for reference.
          def define_field_from_arlington(field_def)
            types = arlington_types_to_ruby(field_def)
            return if types.empty?

            key = arlington_key_to_symbol(field_def.key)
            existing = own_fields[key]
            if existing
              own_fields[key] = merged_field(existing, field_def)
              return
            end

            define_field(
              key,
              type: types.length == 1 ? types.first : types,
              required: arlington_required?(field_def),
              default: arlington_default(field_def),
              version: arlington_version(field_def),
              arlington: field_def
            )
          end
          private :define_field_from_arlington

          def merged_field(existing, field_def)
            Fields::Field.new(
              existing.pdf_name,
              type: existing.type,
              required: existing.required,
              default: existing.default,
              indirect: existing.indirect,
              allowed_values: existing.allowed_values,
              version: arlington_version(field_def),
              arlington: field_def
            )
          end
          private :merged_field

          def arlington_types_to_ruby(field_def)
            field_def.types.map { |t| arlington_one_type_to_ruby(t) }.flatten.compact.uniq
          end
          private :arlington_types_to_ruby

          def arlington_one_type_to_ruby(t)
            case t
            when :boolean then [TrueClass, FalseClass]
            when :integer then Integer
            when :number then [Integer, Float]
            when :name then Symbol
            when :string, :"string-ascii", :"string-text" then String
            when :"string-byte" then Fields::PDFByteString
            when :array then Pdfrb::Model::PdfArray
            when :dictionary then Pdfrb::Model::Cos::Dictionary
            when :stream then Pdfrb::Model::Cos::Stream
            when :null then NilClass
            when :date then Fields::PDFDate
            when :rectangle then Pdfrb::Model::Rectangle
            when :matrix then Pdfrb::Model::Matrix
            when :bitmask then Integer
            when :"name-tree", :"number-tree" then Pdfrb::Model::Cos::Dictionary
            end
          end
          private :arlington_one_type_to_ruby

          def arlington_key_to_symbol(key)
            key.to_sym
          end
          private :arlington_key_to_symbol

          def arlington_required?(field_def)
            field_def.required_literal == true
          end
          private :arlington_required?

          def arlington_default(field_def)
            return nil if field_def.default_value.nil?

            field_def.default_value
          end
          private :arlington_default

          def arlington_version(field_def)
            field_def.since_version.to_s
          end
          private :arlington_version
        end

        def initialize(value = {}, oid: 0, gen: 0, document: nil)
          value ||= {}
          unless value.is_a?(::Hash)
            raise ArgumentError, "Dictionary value must be a Hash, got #{value.class}"
          end

          super(value, oid: oid, gen: gen, document: document)
          apply_required_defaults
        end

        # Typed access. Resolves References, wraps in field-specific
        # subclass, applies default, runs converters.
        def [](name)
          name = name.to_sym unless name.is_a?(::Symbol)
          field = self.class.field(name)
          data = @value[name]
          data = field.default if data.nil? && field&.default?
          return nil if data.nil?

          data = dereference(data)
          data = data.value if unbox_object?(data)

          return data unless field

          converted = Fields.apply(field, data, document)
          if converted
            @value[name] = converted
            converted
          else
            data
          end
        end

        def []=(name, value)
          raise ArgumentError, "Dictionary keys must be Symbols" unless name.is_a?(::Symbol)

          @value[name] = value
        end

        def key?(name)
          name = name.to_sym unless name.is_a?(::Symbol)
          !@value[name].nil?
        end

        def delete(name)
          name = name.to_sym unless name.is_a?(::Symbol)
          @value.delete(name)
        end

        # Iterate (Symbol, processed-value) pairs. Slower than #each_raw
        # because it runs the full accessor pipeline; use that when
        # you don't need wrapping.
        def each
          return enum_for(:each) unless block_given?

          @value.each_key { |k| yield(k, self[k]) }
          self
        end

        # Iterate (Symbol, raw-value) pairs without accessor pipeline.
        def each_raw
          return enum_for(:each_raw) unless block_given?

          @value.each { |k, v| yield(k, v) }
          self
        end

        def keys; @value.keys; end
        def empty?; @value.empty?; end

        def pdf_type
          self.class.pdf_type || self[:Type]
        end

        # Walk every declared field and yield (message, correctable)
        # for each violation. Returns an Enumerator if no block given.
        def validate
          return enum_for(:validate) unless block_given?

          self.class.each_field do |name, field|
            validate_one(name, field) { |*a| yield(*a) }
          end
        end

        protected

        def dereference(data)
          return data unless data.is_a?(Pdfrb::Model::Reference)
          return data if document.nil?

          data.deref(document)
        end

        # PDF Boolean values can come back as Ruby +true+/+false+, as the
        # strings +"true"+/+"false"+ (from arlington defaults), or as
        # +nil+ when absent. Normalise to a Ruby boolean.
        def truthy?(value)
          return false if value.nil? || value == false
          return true if value == true
          return false if value.to_s.downcase == "false"
          return false if value.to_s.downcase == "no"

          !!value
        end

        private

        def unbox_object?(obj)
          obj.is_a?(Pdfrb::Model::Object) && !obj.is_a?(Pdfrb::Model::Cos::Dictionary)
        end

        def apply_required_defaults
          self.class.each_field do |name, field|
            next if @value.key?(name) || !field.required? || !field.default?

            @value[name] = field.default
          end
        end

        def validate_one(name, field)
          value = key?(name) ? self[name] : nil
          if field.required? && value.nil?
            yield("Required field #{name} is missing", field.default?)
            self[name] = field.default if field.default?
            return
          end
          return if value.nil?

          unless field.valid_value?(value)
            yield("Field #{name} has wrong type: #{value.class}", !field.required?)
            return
          end

          return unless field.has_allowed_values?
          return if field.allowed_values.include?(value)

          yield("Field #{name} has disallowed value: #{value.inspect}", false)
        end
      end
    end
  end
end
