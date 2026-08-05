# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Optional Content Configuration (s8.11.4.1). Per-view configuration
      # of OCG visibility, intent, and locking.
      class OptionalContentConfiguration < Cos::Dictionary
        register_type :OCConfig

        def type; self[:Type]; end
        def name; self[:Name]; end
        def creator; self[:Creator]; end
        def base_state; (self[:BaseState] || :ON).to_sym; end
        def on; self[:ON]; end
        def off; self[:OFF]; end
        def intent; self[:Intent]; end
        def list_mode; self[:ListMode]&.to_sym || :AllPages; end
        def rb_groups; self[:RBGroups]; end
        def locked; self[:Locked]; end

        def all_on?; base_state == :ON; end
        def all_off?; base_state == :OFF; end
        def unchanged?; base_state == :Unchanged; end

        def has_intent?
          !!intent
        end

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

        def locked_groups?
          !!locked
        end

        def radio_button_groups?
          !!rb_groups
        end
      end
    end
  end
end
