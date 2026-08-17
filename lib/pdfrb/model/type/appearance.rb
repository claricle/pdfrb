# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Appearance stream dictionary (s12.5.5). The /AP dict on an
      # annotation holds three sub-dicts: /N (normal), /R (rollover),
      # /D (down).
      class Appearance < Pdfrb::Model::Cos::Dictionary
        arlington_object "Appearance"
        def normal; self[:N]; end
        def rollover; self[:R]; end
        def down; self[:D]; end

        # Presence checks use the raw value (not the Arlington
        # default) because /D defaults to /N's value per the spec.
        def has_normal?
          !value[:N].nil?
        end

        def has_rollover?
          !value[:R].nil?
        end

        def has_down?
          !value[:D].nil?
        end

        def normal_for_state(state_name)
          return nil unless normal

          n = if normal.is_a?(Pdfrb::Model::Reference) && document
                document.object(normal)
              else
                normal
              end
          return nil unless n.is_a?(Hash)

          n[state_name]
        end
      end
    end
  end
end
