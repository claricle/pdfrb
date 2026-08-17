# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Named action (s12.6.4.19). Pre-defined action by name (NextPage,
      # PrevPage, FirstPage, LastPage, Print, etc.).
      class ActionNamed < Action
        arlington_object "ActionNamed"
        register_subtype :Named

        def action_name; self[:N]; end

        def next_page?; action_name&.to_sym == :NextPage; end
        def prev_page?; action_name&.to_sym == :PrevPage; end
        def first_page?; action_name&.to_sym == :FirstPage; end
        def last_page?; action_name&.to_sym == :LastPage; end
        def print?; action_name&.to_sym == :Print; end
        def save?; action_name&.to_sym == :Save; end
        def find?; action_name&.to_sym == :Find; end
      end
    end
  end
end
