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

