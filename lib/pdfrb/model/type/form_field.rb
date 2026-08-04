# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Field < Cos::Dictionary
        register_type :Annot

        def field_type; self[:FT]; end
        def field_name; self[:T]; end
        def field_value; self[:V]; end
        def kids; self[:Kids]; end
        def flags; self[:Ff] || 0; end
      end

      class TextField < Field
        def max_len; self[:MaxLen]; end
        def value; self[:V]; end
      end

      class Button < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end
      end

      class Choice < Field
        def value; self[:V]; end
        def opt; self[:Opt]; end
        def top_index; self[:TI]; end
      end

      class SignatureField < Field
        def value; self[:V]; end
      end
    end
  end
end
