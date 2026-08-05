# frozen_string_literal: true

module Pdfrb
  module Model
    # Semantic PDF types — one subclass per Arlington TSV. Each class
    # declares `arlington_object "Name"` and gets its field metadata
    # auto-loaded from the vendored TSVs at first access.
    #
    # The +arlington_registry+ maps TSV name -> Type subclass so other
    # Types' field-link resolution can find concrete classes.
    #
    # Adding a new PDF type = adding one subclass that calls
    # `arlington_object "TSVName"`. Open/closed: no switch edits.
    module Type
      @arlington_registry = {}

      class << self
        attr_reader :arlington_registry

        # Register a Type subclass under its Arlington TSV name.
        def register_arlington(name, klass)
          @arlington_registry[name] = klass
        end

        # Look up a Type subclass by Arlington TSV name.
        def lookup(name)
          @arlington_registry[name]
        end
      end

      # Base semantic types (one file per TSV cluster).
      autoload :FileTrailer, "pdfrb/model/type/file_trailer"
      autoload :Catalog, "pdfrb/model/type/catalog"
      autoload :Info, "pdfrb/model/type/info"
      autoload :PageTreeNode, "pdfrb/model/type/page_tree_node"
      autoload :PageTreeNodeRoot, "pdfrb/model/type/page_tree_node"
      autoload :Page, "pdfrb/model/type/page"
      autoload :Resources, "pdfrb/model/type/resources"
      autoload :Metadata, "pdfrb/model/type/metadata"
      autoload :ObjectStream, "pdfrb/model/type/object_stream"
      autoload :XRefStream, "pdfrb/model/type/xref_stream"
      autoload :GraphicsStateParameter, "pdfrb/model/type/graphics_state_parameter"
      autoload :Names, "pdfrb/model/type/names"
      autoload :Outline, "pdfrb/model/type/outline"
      autoload :OutlineItem, "pdfrb/model/type/outline_item"
      autoload :InteractiveForm, "pdfrb/model/type/interactive_form"
      autoload :OutputIntent, "pdfrb/model/type/output_intent"
      autoload :EncryptionStandard, "pdfrb/model/type/encryption_standard"
      autoload :EncryptionPublicKey, "pdfrb/model/type/encryption_public_key"
      autoload :OptionalContentGroup, "pdfrb/model/type/optional_content_group"
      autoload :OptionalContentMembership, "pdfrb/model/type/optional_content_membership"
      autoload :OptionalContentProperties, "pdfrb/model/type/optional_content_properties"
      autoload :FileSpecification, "pdfrb/model/type/file_specification"
      autoload :EmbeddedFile, "pdfrb/model/type/embedded_file"
      autoload :AFFileSpecification, "pdfrb/model/type/af_file_specification"
      autoload :AFEmbeddedFile, "pdfrb/model/type/af_embedded_file"
      autoload :StructTreeRoot, "pdfrb/model/type/struct_tree_root"
      autoload :StructElem, "pdfrb/model/type/struct_elem"

      # XObject family.
      autoload :XObjectForm, "pdfrb/model/type/xobject_form"
      autoload :XObjectImage, "pdfrb/model/type/xobject_image"

      # Function family (s8.9).
      autoload :Function, "pdfrb/model/type/function"
      autoload :FunctionExponential, "pdfrb/model/type/function_exponential"
      autoload :FunctionStitching, "pdfrb/model/type/function_stitching"
      autoload :FunctionSampled, "pdfrb/model/type/function_sampled"
      autoload :FunctionPostScript, "pdfrb/model/type/function_postscript"

      # Halftone family (s8.7.4).
      autoload :Halftone, "pdfrb/model/type/halftone"
      autoload :HalftoneType1, "pdfrb/model/type/halftone"
      autoload :HalftoneType5, "pdfrb/model/type/halftone"
      autoload :HalftoneType6, "pdfrb/model/type/halftone"
      autoload :HalftoneType10, "pdfrb/model/type/halftone"
      autoload :HalftoneType16, "pdfrb/model/type/halftone"

      # Media (s13.3-4). Legacy media types retained for round-trip.
      autoload :Movie, "pdfrb/model/type/movie"
      autoload :Sound, "pdfrb/model/type/sound"

      # Color space dicts (s8.6).
      autoload :CalGray, "pdfrb/model/type/color_space_dict"
      autoload :CalRGB, "pdfrb/model/type/color_space_dict"
      autoload :Lab, "pdfrb/model/type/color_space_dict"
      autoload :Indexed, "pdfrb/model/type/color_space_dict"
      autoload :Separation, "pdfrb/model/type/color_space_dict"
      autoload :DeviceN, "pdfrb/model/type/color_space_dict"

      # Pattern family (s8.7).
      autoload :Pattern, "pdfrb/model/type/pattern"
      autoload :PatternTiling, "pdfrb/model/type/pattern"
      autoload :PatternShading, "pdfrb/model/type/pattern"

      # Font family.
      autoload :Font, "pdfrb/model/type/font"
      autoload :FontType1, "pdfrb/model/type/font_type1"
      autoload :FontTrueType, "pdfrb/model/type/font_true_type"
      autoload :FontType0, "pdfrb/model/type/font_type0"
      autoload :FontType3, "pdfrb/model/type/font_type3"
      autoload :CIDFont, "pdfrb/model/type/cid_font"
      autoload :CIDSystemInfo, "pdfrb/model/type/cid_system_info"
      autoload :FontDescriptor, "pdfrb/model/type/font_descriptor"

      # Annotation + Action families (with subtype dispatch).
      autoload :Annotation, "pdfrb/model/type/annotation"
      autoload :MarkupAnnotation, "pdfrb/model/type/markup_annotation"
      autoload :WidgetAnnotation, "pdfrb/model/type/widget_annotation"
      autoload :LinkAnnotation, "pdfrb/model/type/link_annotation"
      autoload :TextAnnotation, "pdfrb/model/type/text_annotation"
      autoload :FreeTextAnnotation, "pdfrb/model/type/free_text_annotation"
      autoload :StampAnnotation, "pdfrb/model/type/stamp_annotation"
      autoload :SquareAnnotation, "pdfrb/model/type/square_annotation"
      autoload :CircleAnnotation, "pdfrb/model/type/circle_annotation"
      autoload :LineAnnotation, "pdfrb/model/type/line_annotation"
      autoload :PolygonAnnotation, "pdfrb/model/type/polygon_annotation"
      autoload :PolylineAnnotation, "pdfrb/model/type/polyline_annotation"
      autoload :InkAnnotation, "pdfrb/model/type/ink_annotation"
      autoload :TextMarkupAnnotation, "pdfrb/model/type/text_markup_annotation"
      autoload :HighlightAnnotation, "pdfrb/model/type/text_markup_annotation"
      autoload :UnderlineAnnotation, "pdfrb/model/type/text_markup_annotation"
      autoload :SquigglyAnnotation, "pdfrb/model/type/text_markup_annotation"
      autoload :StrikeOutAnnotation, "pdfrb/model/type/text_markup_annotation"
      autoload :PopupAnnotation, "pdfrb/model/type/popup_annotation"
      autoload :FileAttachmentAnnotation, "pdfrb/model/type/file_attachment_annotation"
      autoload :CaretAnnotation, "pdfrb/model/type/caret_annotation"
      autoload :RedactAnnotation, "pdfrb/model/type/redact_annotation"
      autoload :WatermarkAnnotation, "pdfrb/model/type/watermark_annotation"
      autoload :PrinterMarkAnnotation, "pdfrb/model/type/printer_mark_annotation"
      autoload :ScreenAnnotation, "pdfrb/model/type/screen_annotation"
      autoload :SoundAnnotation, "pdfrb/model/type/sound_annotation"
      autoload :Action, "pdfrb/model/type/action"
      autoload :ActionGoTo, "pdfrb/model/type/action_goto"
      autoload :ActionGoToR, "pdfrb/model/type/action_go_to_r"
      autoload :ActionURI, "pdfrb/model/type/action_uri"
      autoload :ActionJavaScript, "pdfrb/model/type/action_java_script"
      autoload :ActionLaunch, "pdfrb/model/type/action_launch"
      autoload :ActionSetOCGState, "pdfrb/model/type/action_set_ocg_state"
      autoload :ActionHide, "pdfrb/model/type/action_hide"
      autoload :ActionSubmitForm, "pdfrb/model/type/action_submit_form"
      autoload :ActionResetForm, "pdfrb/model/type/action_reset_form"
      autoload :ActionImportData, "pdfrb/model/type/action_import_data"
      autoload :ActionTrans, "pdfrb/model/type/action_trans"
      autoload :ActionNamed, "pdfrb/model/type/action_named"
      autoload :ActionRendition, "pdfrb/model/type/action_media"
      autoload :ActionMovie, "pdfrb/model/type/action_media"
      autoload :ActionSoundAction, "pdfrb/model/type/action_media"
      autoload :ActionSetState, "pdfrb/model/type/action_media"
      autoload :ActionThread, "pdfrb/model/type/action_media"
      autoload :ActionGoTo3DView, "pdfrb/model/type/action_media"
      autoload :ActionGoToDp, "pdfrb/model/type/action_pdf20"
      autoload :ActionRichMediaExecute, "pdfrb/model/type/action_pdf20"
      autoload :ActionNOP, "pdfrb/model/type/action_pdf20"

      # Signature family (s12.8).
      autoload :Signature, "pdfrb/model/type/signature"
      autoload :SigFieldLock, "pdfrb/model/type/signature"
      autoload :SigFieldSeedValue, "pdfrb/model/type/signature"
      autoload :DocMDPTransformParameters, "pdfrb/model/type/signature"
    end
  end
end
