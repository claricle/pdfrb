# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Field < Cos::Dictionary
        register_type :Annot

        def field_type; self[:FT]; end
        def field_name; self[:T]; end
        def alternate_field_name; self[:TU]; end
        def mapping_field_name; self[:TM]; end
        def field_value; self[:V]; end
        def default_value; self[:DV]; end
        def kids; self[:Kids]; end
        def parent; self[:Parent]; end
        def flags; self[:Ff] || 0; end
        def additional_actions; self[:AA]; end
        def appearance_characteristics; self[:MK]; end

        def button?; field_type&.to_sym == :Btn; end
        def text?; field_type&.to_sym == :Tx; end
        def choice?; field_type&.to_sym == :Ch; end
        def signature?; field_type&.to_sym == :Sig; end

        def read_only?; flags & 1 != 0; end
        def required?; flags & 2 != 0; end
        def no_export?; flags & 4 != 0; end

        def has_kids?
          kids && (!kids.is_a?(Array) || !kids.empty?)
        end

        def terminal_field?
          !has_kids?
        end

        def resolved_parent
          ref = parent
          return nil unless ref && document
          document.object(ref)
        end

        def root_field
          cur = self
          while cur && cur.parent
            parent_ref = cur.parent
            cur = parent_ref.is_a?(Pdfrb::Model::Reference) && document ?
                    document.object(parent_ref) : parent_ref
          end
          cur
        end

        def fully_qualified_name
          parts = []
          cur = self
          while cur
            parts << cur.field_name if cur.field_name
            parent_ref = cur.parent
            break unless parent_ref && document
            cur = document.object(parent_ref)
          end
          parts.reverse.join(".")
        end
      end

      class TextField < Field
        def max_len; self[:MaxLen]; end
        def value; self[:V]; end
        def rich_text_value; self[:RV]; end

        def multiline?; flags & 0x1000 != 0; end
        def password?; flags & 0x2000 != 0; end
        def file_select?; flags & 0x100000 != 0; end
        def do_not_spell_check?; flags & 0x400000 != 0; end
        def do_not_scroll?; flags & 0x800000 != 0; end
        def comb?; flags & 0x1000000 != 0; end
        def rich_text?; flags & 0x2000000 != 0; end
      end

      class Button < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end

        def push_button?; flags & 0x10000 != 0; end
        def radio?; flags & 0x8000 != 0; end
        def no_toggle_to_off?; flags & 0x4000 != 0; end
        def radios_in_unison?; flags & 0x2000000 != 0; end
      end

      class Choice < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end
        def top_index; self[:TI]; end
        def indices; self[:I]; end

        def combo?; flags & 0x20000 != 0; end
        def list?; !combo?; end
        def edit?; flags & 0x40000 != 0; end
        def multi_select?; flags & 0x200000 != 0; end
        def sort?; flags & 0x80000 != 0; end
        def commit_on_change?; flags & 0x4000000 != 0; end
      end

      class SignatureField < Field
        def value; self[:V]; end
        def lock; self[:Lock]; end
        def seed_value; self[:SV]; end

        def signed?
          value && value[:Contents]
        end
      end
    end
  end
end
