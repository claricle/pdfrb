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
    end
  end
end
