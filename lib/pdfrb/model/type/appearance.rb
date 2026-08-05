# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Appearance stream dictionary (s12.5.5). The /AP dict on an
      # annotation holds three sub-dicts: /N (normal), /R (rollover),
      # /D (down).
      class Appearance < Pdfrb::Model::Cos::Dictionary
        def normal; self[:N]; end
        def rollover; self[:R]; end
        def down; self[:D]; end

        def has_normal?
          !!normal
        end

        def has_rollover?
          !!rollover
        end

        def has_down?
          !!down
        end

        def normal_for_state(state_name)
          return nil unless normal

          n = if normal.is_a?(Pdfrb::Model::Reference) && document
                document.object(normal)
              else
                normal
              end
          return nil unless n.respond_to?(:[])

          n[state_name]
        end
      end
    end
  end
end
