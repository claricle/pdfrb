# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # Field metadata for a Dictionary entry. Field instances are
      # created by `Dictionary.define_field` (hand-coded) or by
      # `arlington_object` (TSV-driven). They drive type conversion,
      # default application, and validation.
      module Fields
        # Use this constant for boolean fields.
        Boolean = [TrueClass, FalseClass].freeze

        # Marker class for binary-encoded string fields.
        PDFByteString = Class.new do
          private_class_method :new
        end.freeze

        # Marker class for date fields (string in PDF, Time in Ruby).
        PDFDate = Class.new do
          private_class_method :new
        end.freeze

        # One declared field on a Dictionary subclass.
        class Field
          attr_reader :pdf_name, :type, :required, :default, :indirect,
                      :allowed_values, :version, :arlington

          def initialize(pdf_name, type:, required: false, default: nil,
                         indirect: nil, allowed_values: nil, version: "1.0",
                         arlington: nil)
            @pdf_name = pdf_name
            @type = [type].flatten.freeze
            @required = required
            @default = default
            @indirect = indirect
            @allowed_values = allowed_values && [allowed_values].flatten.freeze
            @version = version
            @arlington = arlington
            freeze
          end

          def required?; !!@required; end
          def default?; !@default.nil?; end
          def has_allowed_values?; !@allowed_values.nil?; end

          # Resolve Symbol types via Dictionary.type_map. Returns an
          # array of Class objects (or empty if no resolution yet).
          def resolved_types
            @type.map do |t|
              next t unless t.is_a?(Symbol)
              Pdfrb::Model::Cos::Dictionary.lookup_type(t)
            end.compact
          end

          def valid_value?(value)
            types = resolved_types
            return true if types.empty?

            types.any? do |t|
              case value
              when Pdfrb::Model::Object
                t === value.value || value.is_a?(t)
              else
                t === value
              end
            end
          end
        end

        # ---- Converter modules ----
        # Stateless. `usable_for?(type)` filters; `convert(data, type,
        # document)` returns the converted value or nil to fall through.

        module DictionaryConverter
          module_function

          def usable_for?(type)
            return true if type.is_a?(Symbol)
            type.is_a?(Class) && type <= Pdfrb::Model::Cos::Dictionary
          end

          def additional_types; ::Hash; end

          def convert(data, type, document)
            first = type.first
            return if first.nil?
            return if data.is_a?(first) && !upgradeable?(data, first)
            return unless data.is_a?(::Hash) || data.is_a?(Pdfrb::Model::Cos::Dictionary)

            # No `type:` — let document#wrap dispatch via /Type so a
            # field typed as bare Cos::Dictionary still upgrades to a
            # specific Type::* subclass when the value has a /Type.
            document&.wrap(data)
          end

          def upgradeable?(data, declared)
            # Already-typed subclass of declared base — leave alone.
            return false unless data.is_a?(Pdfrb::Model::Cos::Dictionary)
            return false if data.class == Pdfrb::Model::Cos::Dictionary

            data.class <= declared
          end
          module_function :upgradeable?
        end

        module ArrayConverter
          module_function

          def usable_for?(type); type == Pdfrb::Model::PdfArray; end
          def additional_types; ::Array; end

          def convert(data, _type, document)
            return unless data.is_a?(::Array)
            return data if data.is_a?(Pdfrb::Model::PdfArray)

            document&.wrap(data, type: Pdfrb::Model::PdfArray)
          end
        end

        module StringConverter
          module_function

          def usable_for?(type); type == ::String; end
          def additional_types; nil; end

          def convert(str, _type, document)
            return unless str.is_a?(::String)
            return unless str.encoding == Encoding::BINARY

            handler = document&.config&.[]("document.on_invalid_string")
            decoded = StringEncoding.decode_text(str, on_invalid: handler)
            decoded&.encode(Encoding::UTF_8)
          end
        end

        module ByteStringConverter
          module_function

          def usable_for?(type); type == PDFByteString; end
          def additional_types; ::String; end

          def convert(str, _type, _document)
            return unless str.is_a?(::String)
            return str if str.encoding == Encoding::BINARY

            str.dup.force_encoding(Encoding::BINARY)
          end
        end

        module DateConverter
          module_function

          def usable_for?(type); type == PDFDate; end
          def additional_types; [::String, ::Time]; end

          def convert(value, _type, _document)
            case value
            when ::Time then value
            when ::String then (Pdfrb::Model::Date.parse(value) rescue nil)
            end
          end
        end

        module RectangleConverter
          module_function

          def usable_for?(type); type == Pdfrb::Model::Rectangle; end
          def additional_types; [::Array, Pdfrb::Model::PdfArray]; end

          def convert(data, _type, _document)
            return unless data.is_a?(::Array) || data.is_a?(Pdfrb::Model::PdfArray)
            return nil if data.empty?

            Pdfrb::Model::Rectangle.from_array(data.to_a)
          end
        end

        module IntegerConverter
          module_function

          def usable_for?(type); type == ::Integer; end
          def additional_types; nil; end

          def convert(data, _type, _document)
            return unless data.is_a?(::Float) && data == data.to_i

            data.to_i
          end
        end

        CONVERTERS = [
          DictionaryConverter, ArrayConverter, StringConverter,
          ByteStringConverter, DateConverter, RectangleConverter,
          IntegerConverter
        ].freeze

        def self.converter_for(type)
          CONVERTERS.find { |c| c.usable_for?(type) }
        end

        def self.apply(field, data, document)
          field.type.each do |t|
            converter = converter_for(t)
            next unless converter

            result = converter.convert(data, field.type, document)
            return result if result
          end
          nil
        end
      end
    end
  end
end
