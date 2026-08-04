# frozen_string_literal: true
module Pdfrb; module Model; module Type
  class ActionGoToR < Cos::Dictionary
    register_type action_type: :GoToR
    def file_spec; self[:F]; end
    def destination; self[:D]; end
    def new_window?; self[:NewWindow] == true; end
  end
end; end; end
