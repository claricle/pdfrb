# frozen_string_literal: true
module Pdfrb; module Model; module Type
  class LineEndingStyling < Cos::Dictionary
    register_type :LineEndingStyling
    def line_start; self[:LE]&.first; end
    def line_end; self[:LE]&.last; end
  end
end; end; end
