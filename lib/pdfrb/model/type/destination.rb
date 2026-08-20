# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Explicit destination array [page, display_type, *params]
      # (s12.3.2.2). Element 0 is a page reference (or integer page
      # number); element 1 names the display mode.
      class Destination < Pdfrb::Model::PdfArray
        def page_ref; self[0]; end
        def display_type; self[1]; end

        # True when element 0 is an integer page number (GoTo D form).
        def page_number?
          page_ref.is_a?(Integer)
        end

        def page_number
          page_ref if page_number?
        end

        def xyz?; display_type == :XYZ; end
        def fit?; display_type == :Fit; end
        def fit_h?; display_type == :FitH; end
        def fit_v?; display_type == :FitV; end
        def fit_r?; display_type == :FitR; end
        def fit_b?; display_type == :FitB; end
        def fit_bh?; display_type == :FitBH; end
        def fit_bv?; display_type == :FitBV; end
      end

      # [page, :XYZ, left, top, zoom] — window positioned at a point
      # (s12.3.2.2, Table 151).
      class DestinationXYZ < Destination
        arlington_object "DestXYZArray"

        def left; self[2]; end
        def top; self[3]; end
        def zoom; self[4]; end

        def retains_position?
          left.nil? && top.nil?
        end
      end

      # [page, :Fit] — whole page fits the window (s12.3.2.2).
      class DestinationFit < Destination
        arlington_object "Dest0Array"
      end

      # [page, :FitH, top] — page width fits the window (s12.3.2.2).
      class DestinationFitH < Destination
        arlington_object "Dest1Array"

        def top; self[2]; end
      end

      # [page, :FitR, left, bottom, right, top] — rectangle fits the
      # window (s12.3.2.2).
      class DestinationFitR < Destination
        arlington_object "Dest4Array"

        def left; self[2]; end
        def bottom; self[3]; end
        def right; self[4]; end
        def top; self[5]; end
      end

      # Structure-destination variants (s7.9.4, PDF 1.3+ tagging).
      # Element 0 may be a structure element reference (string) instead
      # of a page — used by GoToE /D chains with structure content.
      class DestinationXYZStruct < DestinationXYZ
        arlington_object "DestXYZStructArray"

        def struct_ref?; page_ref.is_a?(String); end
      end

      class DestinationFitStruct < DestinationFit
        arlington_object "Dest0StructArray"

        def struct_ref?; page_ref.is_a?(String); end
      end

      class DestinationFitHStruct < DestinationFitH
        arlington_object "Dest1StructArray"

        def struct_ref?; page_ref.is_a?(String); end
      end

      class DestinationFitRStruct < DestinationFitR
        arlington_object "Dest4StructArray"

        def struct_ref?; page_ref.is_a?(String); end
      end

      # Destination dictionary (s12.3.2.3). Wraps a destination in
      # target-dictionary chains (GoToE /D). /SD is the structure
      # destination form.
      class DestinationDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "DestDict"

        def d; self[:D]; end
        def sd; self[:SD]; end

        def structure_destination?
          !sd.nil?
        end
      end

      # /Dests dictionary (s7.7.4, deprecated 2.0). Name → destination
      # map living on the (page or) catalog.
      class DestsMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "DestsMap"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def add(name, destination)
          value[name.to_sym] = destination
          name.to_sym
        end

        def each_destination(&)
          return enum_for(:each_destination) unless block_given?

          value.each(&)
        end

        def names
          value.keys
        end
      end
    end
  end
end
