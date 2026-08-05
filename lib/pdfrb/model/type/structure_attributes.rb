# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure Attributes Dictionary (s14.7.5). Per-structure-element
      # attributes — owner + per-owner attribute fields (Layout, Table,
      # List, PrintField, etc.).
      class StructureAttributes < Pdfrb::Model::Cos::Dictionary
        def owner; self[:O]; end
        def namespace; self[:NS]; end
        def placement; self[:Placement]&.to_sym; end
        def writing_mode; (self[:WritingMode] || :LrTb).to_sym; end
        def background_color; self[:BackgroundColor]; end
        def border_color; self[:BorderColor]; end
        def border_style; self[:BorderStyle]; end
        def border_thickness; self[:BorderThickness]; end
        def padding; self[:Padding]; end
        def color; self[:Color]; end
        def text_align; self[:TextAlign]&.to_sym; end
        def width; self[:Width]; end
        def height; self[:Height]; end
        def space_before; self[:SpaceBefore]; end
        def space_after; self[:SpaceAfter]; end
        def start_indent; self[:StartIndent]; end
        def end_indent; self[:EndIndent]; end
        def text_indent; self[:TextIndent]; end
        def line_height; self[:LineHeight]; end

        def layout_owner?; owner == :Layout; end
        def list_owner?; owner == :List; end
        def table_owner?; owner == :Table; end
        def print_field_owner?; owner == :PrintField; end
        def artifact_owner?; owner == :Artifact; end
        def xml_owner?; owner.to_s.start_with?("XML", "HTML"); end
        def user_properties_owner?; owner == :UserProperties; end

        def has_namespace?
          !!namespace
        end
      end
    end
  end
end
