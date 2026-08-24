# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure Attributes Dictionary (s14.7.5). Per-structure-element
      # attributes — owner + per-owner attribute fields (Layout, Table,
      # List, PrintField, etc.).
      class StructureAttributes < Pdfrb::Model::Cos::Dictionary
        arlington_object "StructureAttributesDict"
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

      # Role map (s14.7.3, StructTreeRoot /RoleMap): custom element
      # names mapped to standard structure types.
      class RoleMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "RoleMap"

        def [](custom_name)
          value[custom_name.to_sym] || value[custom_name.to_s]
        end

        def custom_names
          value.keys
        end
      end

      # Namespaced role map (s14.7.3, /RoleMapNS): per-namespace role
      # maps keyed by namespace URI.
      class RoleMapNS < Pdfrb::Model::Cos::Dictionary
        arlington_object "RoleMapNS"

        def [](namespace)
          value[namespace.to_sym] || value[namespace.to_s]
        end
      end

      # Style dictionary (s14.9.2, /Styles entries): number-of-style
      # to style-attributes mapping with an optional /Panose.
      class StyleDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "StyleDict"

        def panose; self[:Panose]; end
      end

      # Class map (s14.7.4, StructTreeRoot /ClassMap): reusable
      # attribute-owner dictionaries shared by structure elements.
      class ClassMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "ClassMap"

        def [](class_name)
          value[class_name.to_sym] || value[class_name.to_s]
        end

        def class_names
          value.keys
        end
      end

      # Reference structure element kid (s14.8.2.4, /Reference):
      # points at content elsewhere via /F file, /Page, /ID.
      class StructureReference < Pdfrb::Model::Cos::Dictionary
        arlington_object "Reference"

        def file; self[:F]; end
        def page; self[:Page]; end
        def ids; self[:ID]; end
      end
    end
  end
end
