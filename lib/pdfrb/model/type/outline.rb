# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Outline (bookmark) root (s12.3.3). Linked from Catalog /Outlines.
      class Outline < Pdfrb::Model::Cos::Dictionary
        arlington_object "Outline"
        register_type :Outlines

        def type; self[:Type]; end
        def first; self[:First]; end
        def last; self[:Last]; end
        def count; self[:Count]; end

        def empty?
          !first
        end

        def has_items?
          !!first
        end

        def resolved_first
          ref = first
          return nil unless ref && document

          document.object(ref)
        end

        def resolved_last
          ref = last
          return nil unless ref && document

          document.object(ref)
        end

        def each_item(&block)
          return enum_for(:each_item) unless block
          return unless first && document

          cur_ref = first
          while cur_ref
            item = document.object(cur_ref)
            break unless item

            yield item
            cur_ref = item[:Next]
          end
        end
      end
    end
  end
end
