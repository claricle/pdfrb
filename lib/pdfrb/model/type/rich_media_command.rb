# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Command (s13.6.4). A command sent to a rich media
      # instance.
      class RichMediaCommand < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def command_name; self[:Cmd]; end
        def arguments; self[:Args]; end

        def has_arguments?
          !!arguments && (!arguments.is_a?(Array) || !arguments.empty?)
        end
      end
    end
  end
end
