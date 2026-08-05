# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Action base class (s12.6). Like annotations, action subtypes
      # each have their own TSV (ActionGoTo, ActionURI, ...) so the
      # common fields are hand-coded here.
      class Action < Pdfrb::Model::Cos::Dictionary
        define_field :Type, type: Symbol, default: :Action
        define_field :S, type: Symbol, required: true
        define_field :Next, type: Pdfrb::Model::PdfArray

        register_type :Action

        def subtype; self[:S]; end
        def next_action; self[:Next]; end

        def next_actions
          value = self[:Next]
          return [] unless value

          value.is_a?(Pdfrb::Model::PdfArray) ? value.to_a : value
        end

        def goto?
          subtype&.to_sym == :GoTo
        end

        def uri?
          subtype&.to_sym == :URI
        end

        def launch?
          subtype&.to_sym == :Launch
        end

        def javascript?
          subtype&.to_sym == :JavaScript
        end

        def named?
          subtype&.to_sym == :Named
        end

        def uri
          return nil unless uri?

          self[:URI]
        end

        def d
          return nil unless goto?

          self[:D]
        end

        class << self
          def subtype_map
            @subtype_map ||= {}
          end

          def register_subtype(symbol, klass = self)
            subtype_map[symbol] = klass
          end

          def for_subtype(symbol)
            subtype_map[symbol]
          end
        end
      end
    end
  end
end

