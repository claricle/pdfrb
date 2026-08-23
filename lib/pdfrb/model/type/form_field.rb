# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Field < Cos::Dictionary
        arlington_object "Field"
        register_type :Field

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
          while cur&.parent
            parent_ref = cur.parent
            cur = if parent_ref.is_a?(Pdfrb::Model::Reference) && document
                    document.object(parent_ref)
                  else
                    parent_ref
                  end
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
    end
  end
end
