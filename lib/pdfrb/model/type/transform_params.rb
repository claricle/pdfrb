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

      # UR Transform Parameters (s12.8.2.3). Adobe Reader-enabled
      # usage rights — annotations, form fill-in, signatures allowed.
      class URTransformParameters < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def annotations; self[:Annots]; end
        def form; self[:Form]; end
        def signature; self[:Signature]; end
        def ef; self[:EF]; end

        def has_annotation_rights?
          !!annotations
        end

        def has_form_rights?
          !!form
        end

        def has_signature_rights?
          !!signature
        end

        def has_embedded_file_rights?
          !!ef
        end
      end
    end
  end
end
