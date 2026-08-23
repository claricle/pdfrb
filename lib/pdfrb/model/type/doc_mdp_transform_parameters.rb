# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Document Modification Detection and Prevention (DocMDP) —
      # s12.8.2.2. Restricts what edits are allowed after signing.
      class DocMDPTransformParameters < Pdfrb::Model::Cos::Dictionary
        arlington_object "DocMDPTransformParameters"
        def type; self[:Type]; end
        def p; self[:P]; end
        def v; self[:V]; end

        # P=1: no changes allowed; P=2: minimal changes (form fill);
        # P=3: annotations + form fill.
        def no_changes_allowed?; p == 1; end
        def minimal_changes_allowed?; p == 2; end
        def annotations_allowed?; p == 3; end
      end
    end
  end
end
