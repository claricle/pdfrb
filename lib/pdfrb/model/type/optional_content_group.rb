# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Optional Content Group (s8.11.2). Layer toggle for PDF layers.
      class OptionalContentGroup < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentGroup"
        register_type :OCG

        def type; self[:Type]; end
        def name; self[:Name]; end
        def intent; self[:Intent]; end
        def usage; self[:Usage]; end

        def view_intent?
          return true unless intent
          arr = intent.is_a?(Pdfrb::Model::PdfArray) ? intent.to_a : intent
          arr = [arr] unless arr.is_a?(Array)
          arr.map(&:to_sym).include?(:View)
        end

        def print_intent?
          return false unless intent
          arr = intent.is_a?(Pdfrb::Model::PdfArray) ? intent.to_a : intent
          arr = [arr] unless arr.is_a?(Array)
          arr.map(&:to_sym).include?(:Print)
        end

        def export_intent?
          return false unless intent
          arr = intent.is_a?(Pdfrb::Model::PdfArray) ? intent.to_a : intent
          arr = [arr] unless arr.is_a?(Array)
          arr.map(&:to_sym).include?(:Export)
        end

        def default_visible?
          usage && usage[:View] && usage[:View][:ViewState]&.to_sym == :ON
        end

        def has_usage?
          !!usage
        end
      end

      # Optional Content Membership (s8.11.4.2). Boolean combination
      # of OCG visibility states.
      class OptionalContentMembership < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentMembership"
        register_type :OCMD

        def ocfgs; self[:OCGs]; end
        def policy; self[:P]; end
        def expression; self[:VE]; end

        def all_on_policy?
          (policy || 1) == 1
        end

        def any_on_policy?
          policy == 2
        end

        def any_off_policy?
          policy == 3
        end

        def has_expression?
          !!expression
        end

        def each_ocg
          return enum_for(:each_ocg) unless block_given?
          return unless ocfgs && document

          arr = ocfgs.is_a?(Pdfrb::Model::Reference) ? document.object(ocfgs) : ocfgs
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end

      # Optional Content Properties (s8.11.1). Catalog /OCProperties.
      class OptionalContentProperties < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentProperties"

        def ocgs; self[:OCGs]; end
        def default_config; self[:D]; end
        def configs; self[:Configs]; end
        def list_mode; self[:ListMode]; end

        def has_configs?
          !!configs
        end

        def base_state
          return :ON_UNLESS_OFF unless default_config
          default_config[:BaseState]&.to_sym || :ON_UNLESS_OFF
        end
      end
    end
  end
end
