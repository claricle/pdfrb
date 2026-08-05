# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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
