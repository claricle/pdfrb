# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # MDP (Modification Detection and Prevention) dict (s12.8.2.2).
      # The /Reference entry on a Signature, with /TransformMethod /DocMDP
      # or /UR (Usage Rights).
      class MDPDict < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def transform_method; self[:TransformMethod]&.to_sym; end
        def transform_params; self[:TransformParams]; end

        def doc_mdp?; transform_method == :DocMDP; end
        def ur?; transform_method == :UR; end
        def field_mdp?; transform_method == :FieldMDP; end
        def identity?; transform_method == :Identity; end

        def resolved_transform_params
          ref = transform_params
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
