# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # ViewerPreferences (s12.2, ISO 32000-2 7.7.2). Catalog /ViewerPreferences.
      class ViewerPreferences < Cos::Dictionary
        arlington_object "ViewerPreferences"
        register_type :ViewerPreferences

        def type; self[:Type]; end
        def hide_toolbar?; truthy?(self[:HideToolbar]); end
        def hide_menubar?; truthy?(self[:HideMenubar]); end
        def hide_window_ui?; truthy?(self[:HideWindowUI]); end
        def fit_window?; truthy?(self[:FitWindow]); end
        def center_window?; truthy?(self[:CenterWindow]); end
        def display_doc_title?; truthy?(self[:DisplayDocTitle]); end
        def non_fullscreen_page_mode; self[:NonFullScreenPageMode]; end
        def direction; self[:Direction]; end
        def view_area; self[:ViewArea]; end
        def view_clip; self[:ViewClip]; end
        def print_area; self[:PrintArea]; end
        def print_clip; self[:PrintClip]; end
        def print_scaling; self[:PrintScaling]; end
        def duplex; self[:Duplex]; end
        def pick_tray_by_pdf_size?; truthy?(self[:PickTrayByPDFSize]); end
        def print_pagerange; self[:PrintPageRange]; end
        def num_copies; self[:NumCopies]; end

        def left_to_right?; direction&.to_sym == :L2R; end
        def right_to_left?; direction&.to_sym == :R2L; end

        def simplex?; duplex&.to_sym == :Simplex; end
        def duplex_flip_short_edge?; duplex&.to_sym == :DuplexFlipShortEdge; end
        def duplex_flip_long_edge?; duplex&.to_sym == :DuplexFlipLongEdge; end

        def enforce_print_scaling?
          print_scaling&.to_sym == :AppDefault
        end
      end
    end
  end
end
