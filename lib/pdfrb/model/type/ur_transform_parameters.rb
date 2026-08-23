# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # UR Transform Parameters (s12.8.2.3). Adobe Reader-enabled
      # usage rights — annotations, form fill-in, signatures allowed.
      class URTransformParameters < Pdfrb::Model::Cos::Dictionary
        arlington_object "URTransformParameters"
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
