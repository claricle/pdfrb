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

      # Base semantic types.
      autoload :FileTrailer, "pdfrb/model/type/file_trailer"
      autoload :Catalog, "pdfrb/model/type/catalog"
      autoload :Info, "pdfrb/model/type/info"
      autoload :PageTreeNode, "pdfrb/model/type/page_tree_node"
      autoload :PageTreeNodeRoot, "pdfrb/model/type/page_tree_node_root"
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

      # Additional OCG / opt-content subclass dicts (one per file).
      autoload :OptContentCreatorInfo, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentExport, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentPrint, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentView, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentLanguage, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentUsage, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentUsageApplication, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentPageElement, "pdfrb/model/type/opt_content_page_element"

      autoload :FileSpecification, "pdfrb/model/type/file_specification"
      autoload :FileSpecEF, "pdfrb/model/type/file_spec_ef"
      autoload :FileSpecRF, "pdfrb/model/type/file_spec_rf"
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
      autoload :HalftoneType1, "pdfrb/model/type/halftone_type1"
      autoload :HalftoneType5, "pdfrb/model/type/halftone_type5"
      autoload :HalftoneType6, "pdfrb/model/type/halftone_type6"
      autoload :HalftoneType10, "pdfrb/model/type/halftone_type10"
      autoload :HalftoneType16, "pdfrb/model/type/halftone_type16"

      # Media (s13.3-4). Legacy media types retained for round-trip.
      autoload :Movie, "pdfrb/model/type/movie"
      autoload :Sound, "pdfrb/model/type/sound"

      # Color space dicts (s8.6).
      autoload :CalGray, "pdfrb/model/type/cal_gray"
      autoload :CalRGB, "pdfrb/model/type/cal_rgb"
      autoload :Lab, "pdfrb/model/type/lab"
      autoload :Indexed, "pdfrb/model/type/indexed"
      autoload :Separation, "pdfrb/model/type/separation"
      autoload :DeviceN, "pdfrb/model/type/device_n"
      autoload :DeviceNMixingHints, "pdfrb/model/type/device_n_mixing_hints"
      autoload :DeviceNProcess, "pdfrb/model/type/device_n_process"
      autoload :ICCBasedColorSpace, "pdfrb/model/type/icc_based_color_space"

      # Pattern family (s8.7).
      autoload :Pattern, "pdfrb/model/type/pattern"
      autoload :PatternTiling, "pdfrb/model/type/pattern_tiling"
      autoload :PatternShading, "pdfrb/model/type/pattern_shading"

      # Font family.
      autoload :Font, "pdfrb/model/type/font"
      autoload :FontType1, "pdfrb/model/type/font_type1"
      autoload :FontTrueType, "pdfrb/model/type/font_true_type"
      autoload :FontType0, "pdfrb/model/type/font_type0"
      autoload :FontType3, "pdfrb/model/type/font_type3"
      autoload :CIDFont, "pdfrb/model/type/cid_font"
      autoload :CIDSystemInfo, "pdfrb/model/type/cid_system_info"
      autoload :CIDFontDescriptorMetrics, "pdfrb/model/type/cid_font_descriptor_metrics"
      autoload :FontCIDType0, "pdfrb/model/type/font_cid_type0"
      autoload :FontCIDType2, "pdfrb/model/type/font_cid_type2"
      autoload :FontDescriptor, "pdfrb/model/type/font_descriptor"
      autoload :FontDescriptorCIDType0, "pdfrb/model/type/font_descriptor_cid_type0"
      autoload :FontDescriptorCIDType2, "pdfrb/model/type/font_descriptor_cid_type2"
      autoload :FontMultipleMaster, "pdfrb/model/type/font_multiple_master"
      autoload :CharProcMap, "pdfrb/model/type/font_multiple_master"
      autoload :FontEncoding, "pdfrb/model/type/font_encoding"
      autoload :ToUnicodeCMapStream, "pdfrb/model/type/to_unicode_cmap_stream"
      autoload :FontFile, "pdfrb/model/type/font_file"
      autoload :FontFile2, "pdfrb/model/type/font_file2"
      autoload :FontFile3, "pdfrb/model/type/font_file3"

      # Annotation family.
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
      autoload :HighlightAnnotation, "pdfrb/model/type/highlight_annotation"
      autoload :UnderlineAnnotation, "pdfrb/model/type/underline_annotation"
      autoload :SquigglyAnnotation, "pdfrb/model/type/squiggly_annotation"
      autoload :StrikeOutAnnotation, "pdfrb/model/type/strikeout_annotation"
      autoload :PopupAnnotation, "pdfrb/model/type/popup_annotation"
      autoload :FileAttachmentAnnotation, "pdfrb/model/type/file_attachment_annotation"
      autoload :CaretAnnotation, "pdfrb/model/type/caret_annotation"
      autoload :RedactAnnotation, "pdfrb/model/type/redact_annotation"
      autoload :WatermarkAnnotation, "pdfrb/model/type/watermark_annotation"
      autoload :PrinterMarkAnnotation, "pdfrb/model/type/printer_mark_annotation"
      autoload :PrinterMarkSubDict, "pdfrb/model/type/transition"
      autoload :ScreenAnnotation, "pdfrb/model/type/screen_annotation"
      autoload :SoundAnnotation, "pdfrb/model/type/sound_annotation"

      # Rich Media annotation family (s13.6).
      autoload :RichMediaAnnotation, "pdfrb/model/type/rich_media_annotation"
      autoload :RichMediaActivation, "pdfrb/model/type/rich_media_activation"
      autoload :RichMediaDeactivation, "pdfrb/model/type/rich_media_deactivation"
      autoload :RichMediaConfiguration, "pdfrb/model/type/rich_media_configuration"
      autoload :RichMediaInstance, "pdfrb/model/type/rich_media_instance"
      autoload :RichMediaCommand, "pdfrb/model/type/rich_media_command"
      autoload :RichMediaContent, "pdfrb/model/type/rich_media_content"
      autoload :RichMediaCuePoint, "pdfrb/model/type/rich_media_cue_point"
      autoload :RichMediaAnimation, "pdfrb/model/type/rich_media_animation"
      autoload :RichMediaWindow, "pdfrb/model/type/rich_media_window"
      autoload :RichMediaSettings, "pdfrb/model/type/rich_media_settings"
      autoload :RichMediaPresentation, "pdfrb/model/type/rich_media_presentation"

      # 3D family (s13.6).
      autoload :ThreeDStream, "pdfrb/model/type/three_d_stream"
      autoload :ThreeDView, "pdfrb/model/type/three_d_view"
      autoload :ThreeDAnimationStyle, "pdfrb/model/type/three_d_animation_style"
      autoload :ThreeDBackground, "pdfrb/model/type/three_d_background"
      autoload :ThreeDLightingScheme, "pdfrb/model/type/three_d_lighting_scheme"
      autoload :ThreeDRenderMode, "pdfrb/model/type/three_d_render_mode"
      autoload :ThreeDCrossSection, "pdfrb/model/type/three_d_cross_section"
      autoload :ThreeDNode, "pdfrb/model/type/three_d_node"
      autoload :ThreeDUnits, "pdfrb/model/type/three_d_units"
      autoload :ThreeDReference, "pdfrb/model/type/three_d_reference"
      autoload :ThreeDActivation, "pdfrb/model/type/three_d_activation"

      # 3D Measure family (s13.6.4).
      autoload :ThreeDMeasure, "pdfrb/model/type/three_d_measure"
      autoload :ThreeDMeasure3DC, "pdfrb/model/type/three_d_measure_3dc"
      autoload :ThreeDMeasurePD3, "pdfrb/model/type/three_d_measure_pd3"
      autoload :ThreeDMeasureLD3, "pdfrb/model/type/three_d_measure_ld3"
      autoload :ThreeDMeasureRD3, "pdfrb/model/type/three_d_measure_rd3"
      autoload :ThreeDMeasureAD3, "pdfrb/model/type/three_d_measure_ad3"

      # Transition + 3D markup + geolocation.
      autoload :Transition, "pdfrb/model/type/transition"
      autoload :ExData3DMarkup, "pdfrb/model/type/transition"
      autoload :ExDataMarkupGeo, "pdfrb/model/type/transition"

      # Appearance generators (one per file).
      autoload :GenericAppearance, "pdfrb/model/type/generic_appearance"
      autoload :WidgetAppearance, "pdfrb/model/type/widget_appearance"
      autoload :TextAppearance, "pdfrb/model/type/text_appearance"
      autoload :LinkAppearance, "pdfrb/model/type/link_appearance"

      # Action family (s12.6.4).
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
      autoload :ActionRendition, "pdfrb/model/type/action_rendition"
      autoload :ActionMovie, "pdfrb/model/type/action_movie"
      autoload :ActionSoundAction, "pdfrb/model/type/action_sound_action"
      autoload :ActionSetState, "pdfrb/model/type/action_set_state"
      autoload :ActionThread, "pdfrb/model/type/action_thread"
      autoload :ActionGoTo3DView, "pdfrb/model/type/action_go_to_3d_view"
      autoload :ActionGoToDp, "pdfrb/model/type/action_go_to_dp"
      autoload :ActionRichMediaExecute, "pdfrb/model/type/action_rich_media_execute"
      autoload :ActionNOP, "pdfrb/model/type/action_nop"

      # Signature family (s12.8).
      autoload :Signature, "pdfrb/model/type/signature"
      autoload :SigFieldLock, "pdfrb/model/type/sig_field_lock"
      autoload :SigFieldSeedValue, "pdfrb/model/type/sig_field_seed_value"
      autoload :DocMDPTransformParameters, "pdfrb/model/type/doc_mdp_transform_parameters"

      # Appearance + Media (s12.5.5, s13.3).
      autoload :Appearance, "pdfrb/model/type/appearance"
      autoload :AppearanceCharacteristics, "pdfrb/model/type/appearance_characteristics"
      autoload :AppearanceTrapNet, "pdfrb/model/type/appearance_trap_net"
      autoload :AppearanceTrapNetSubDict, "pdfrb/model/type/appearance_trap_net"
      autoload :AppearanceSubDict, "pdfrb/model/type/appearance_trap_net"
      autoload :MediaClip, "pdfrb/model/type/media_clip"
      autoload :Rendition, "pdfrb/model/type/rendition"
      autoload :ExDataProjection, "pdfrb/model/type/appearance_trap_net"
      autoload :AnnotationProjectionDict, "pdfrb/model/type/appearance_trap_net"

      # Media offset / player / screen types.
      autoload :MediaOffsetTime, "pdfrb/model/type/media_offset"
      autoload :MediaOffsetFrame, "pdfrb/model/type/media_offset"
      autoload :MediaOffsetMarker, "pdfrb/model/type/media_offset"
      autoload :MediaPlayerInfo, "pdfrb/model/type/media_offset"
      autoload :MediaPlayers, "pdfrb/model/type/media_offset"
      autoload :MediaScreenParameters, "pdfrb/model/type/media_offset"
      autoload :MediaCriteria, "pdfrb/model/type/media_offset"
      autoload :SoftwareIdentifier, "pdfrb/model/type/software_identifier"

      # Misc small helpers (one per file).
      autoload :BorderArray, "pdfrb/model/type/misc_helpers"
      autoload :LabRangeArray, "pdfrb/model/type/misc_helpers"
      autoload :DestOutputProfileRef, "pdfrb/model/type/misc_helpers"
      autoload :OutputIntentsContainer, "pdfrb/model/type/misc_helpers"
      autoload :CMapStream, "pdfrb/model/type/misc_helpers"

      # Crypt filter (s7.6.5).
      autoload :CryptFilter, "pdfrb/model/type/crypt_filter"
      autoload :CryptFilterMap, "pdfrb/model/type/crypt_filter"
      autoload :CryptFilterPublicKey, "pdfrb/model/type/crypt_filter"
      autoload :CryptFilterPublicKeyMap, "pdfrb/model/type/crypt_filter"

      # Signature build data.
      autoload :SignatureBuildPropDict, "pdfrb/model/type/appearance_trap_net"
      autoload :SignatureBuildDataDict, "pdfrb/model/type/signature_build"
      autoload :SignatureBuildDataAppDict, "pdfrb/model/type/signature_build"
      autoload :SignatureBuildDataSigQDict, "pdfrb/model/type/signature_build"
      autoload :SignatureReferenceDocMDP, "pdfrb/model/type/signature_build"
      autoload :SignatureReferenceIdentity, "pdfrb/model/type/signature_build"
      autoload :SignatureReferenceUR, "pdfrb/model/type/signature_build"
      autoload :SignatureReferenceFieldMDP, "pdfrb/model/type/signature_build"

      # Page box color info (s7.7.3.3).
      autoload :BoxColorInfo, "pdfrb/model/type/box_color_info"
      autoload :BoxStyle, "pdfrb/model/type/box_style"

      # Collection / Portfolio (s7.11.5).
      autoload :Collection, "pdfrb/model/type/collection"
      autoload :CollectionSchema, "pdfrb/model/type/collection_schema"
      autoload :CollectionSort, "pdfrb/model/type/collection_sort"
      autoload :CollectionField, "pdfrb/model/type/collection_field"
      autoload :CollectionItem, "pdfrb/model/type/collection_item"

      # Signature transform parameters (s12.8.2).
      autoload :MDPDict, "pdfrb/model/type/mdp_dict"
      autoload :FieldMDPTransformParameters, "pdfrb/model/type/field_mdp_transform_parameters"
      autoload :URTransformParameters, "pdfrb/model/type/ur_transform_parameters"

      # Embedded file params + misc globals.
      autoload :EmbeddedFileParameter, "pdfrb/model/type/embedded_file_parameter"
      autoload :JBIG2Globals, "pdfrb/model/type/jbig2_globals"
      autoload :URLAlias, "pdfrb/model/type/url_alias"
      autoload :URIDict, "pdfrb/model/type/uri_dict"

      autoload :Field, "pdfrb/model/type/form_field"
      autoload :TextField, "pdfrb/model/type/text_field"
      autoload :Button, "pdfrb/model/type/button"
      autoload :Choice, "pdfrb/model/type/choice"
      autoload :SignatureField, "pdfrb/model/type/signature_field"

      # Structure types (s14.7).
      autoload :StructureAttributes, "pdfrb/model/type/structure_attributes"
      autoload :StructureElementKid, "pdfrb/model/type/structure_element_kid"
    end
  end
end
