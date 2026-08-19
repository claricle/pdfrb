# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection subitem (s7.11.5, PDF 1.7 Adobe extension level 3).
      # Assigns one embedded file to a folder via the folder's /P path
      # and the /D display value.
      class CollectionSubitem < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionSubitem"

        def display_value; self[:D]; end
        def parent_folder_path; self[:P]; end

        def numeric_display?
          display_value.is_a?(Numeric)
        end
      end
    end
  end
end
