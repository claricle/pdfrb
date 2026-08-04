# frozen_string_literal: true
module Pdfrb; module Model; module Type
  class ViewerPreferences < Cos::Dictionary
    register_type :ViewerPreferences
    def hide_toolbar?; self[:HideToolbar] == true; end
    def hide_menubar?; self[:HideMenubar] == true; end
    def hide_window_ui?; self[:HideWindowUI] == true; end
    def fit_window?; self[:FitWindow] == true; end
    def center_window?; self[:CenterWindow] == true; end
    def display_doc_title?; self[:DisplayDocTitle] == true; end
    def non_fullscreen_page_mode; self[:NonFullScreenPageMode]; end
    def direction; self[:Direction]; end
    def view_area; self[:ViewArea]; end
    def view_clip; self[:ViewClip]; end
    def print_area; self[:PrintArea]; end
    def print_clip; self[:PrintClip]; end
    def print_scaling; self[:PrintScaling]; end
    def duplex; self[:Duplex]; end
    def pick_tray_by_pdf_size?; self[:PickTrayByPDFSize] == true; end
    def print_pagerange; self[:PrintPageRange]; end
    def num_copies; self[:NumCopies]; end
  end
end; end; end
