# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Single bookmark entry. Lives in its own file so the autoload
      # path matches the TSV-derived class name.
      class OutlineItem < Pdfrb::Model::Cos::Dictionary
        arlington_object "OutlineItem"

        def title; self[:Title]; end
        def parent; self[:Parent]; end
        def prev; self[:Prev]; end
        def next; self[:Next]; end
        def first; self[:First]; end
        def last; self[:Last]; end
        def count; self[:Count]; end
        def dest; self[:Dest]; end
        def action; self[:A]; end
        def se; self[:SE]; end
        def c; self[:C]; end
        def f; self[:F]; end

        def color
          c if c && (!c.is_a?(Array) || !c.empty?)
        end

        def bold?
          f && (f & 1) != 0
        end

        def italic?
          f && (f & 2) != 0
        end

        def has_children?
          !!(count && count.nonzero?)
        end

        def open?
          return true unless count
          count > 0
        end

        def child_count
          return 0 unless count
          count.abs
        end

        def destination
          dest || (action && action[:D])
        end
      end
    end
  end
end
