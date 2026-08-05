# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Output intent (s14.11.5) — ICC profile + condition metadata.
      # Required for PDF/X and PDF/A conformance.
      class OutputIntent < Pdfrb::Model::Cos::Dictionary
        arlington_object "OutputIntents"
        register_type :OutputIntent

        def type; self[:Type]; end
        def output_intent_type; self[:S]; end
        def output_condition; self[:OutputCondition]; end
        def output_condition_identifier; self[:OutputConditionIdentifier]; end
        def registry_name; self[:RegistryName]; end
        def info; self[:Info]; end
        def dest_output_profile; self[:DestOutputProfile]; end
        def dest_output_profile_ref; self[:DestOutputProfileRef]; end

        def pdfx?
          output_intent_type&.to_sym == :GTS_PDFX
        end

        def pdfa?
          [:GTS_PDFA1, :GTS_PDFA2, :GTS_PDFA3].include?(output_intent_type&.to_sym)
        end

        def has_embedded_profile?
          !!dest_output_profile
        end

        def resolved_profile
          ref = dest_output_profile
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
