# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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

          arr = document.resolve(ocfgs)
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |ref|
            obj = document.resolve(ref)
            yield obj if obj
          end
        end
      end
    end
  end
end
