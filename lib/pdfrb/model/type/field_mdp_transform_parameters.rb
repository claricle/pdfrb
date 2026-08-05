# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Field MDP Transform Parameters (s12.7.6.5). Specifies which
      # fields are locked by a FieldMDP signature reference.
      class FieldMDPTransformParameters < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def action; self[:Action]&.to_sym; end
        def fields; self[:Fields]; end

        def all_locked?; action == :All; end
        def include_locked?; action == :Include; end
        def exclude_locked?; action == :Exclude; end

        def locked_field_names
          return [] unless fields

          arr = fields.is_a?(Pdfrb::Model::PdfArray) ? fields.to_a : fields
          arr.is_a?(Array) ? arr : []
        end
      end
    end
  end
end
