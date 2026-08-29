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

        def register_arlington(name, klass)
          @arlington_registry[name] = klass
        end

        def lookup(name)
          @arlington_registry[name]
        end

        # Force-load all autoloaded type classes so register_type and
        # register_subtype calls fire. Call this before parsing or
        # when iterating type_map. Idempotent.
        def eager_load!
          return if @eager_loaded

          constants.each do |c|
            const_get(c)
          rescue NameError
            # Skip autoload targets that don't define a class yet.
          end
          @eager_loaded = true
        end
      end

      autoload :NameMap, "pdfrb/model/type/name_map"

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
      autoload :OptContentUsageApplication, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentPageElement, "pdfrb/model/type/opt_content_page_element"
      autoload :OptContentUser, "pdfrb/model/type/opt_content_ext"
      autoload :OptContentZoom, "pdfrb/model/type/opt_content_ext"

      autoload :FileSpecification, "pdfrb/model/type/file_specification"
      autoload :FileSpecEF, "pdfrb/model/type/file_spec_ef"
      autoload :FileSpecRF, "pdfrb/model/type/file_spec_rf"
      autoload :EmbeddedFile, "pdfrb/model/type/embedded_file"
      autoload :AFFileSpecification, "pdfrb/model/type/af_file_specification"
      autoload :AFEmbeddedFile, "pdfrb/model/type/af_embedded_file"
      autoload :StructTreeRoot, "pdfrb/model/type/struct_tree_root"
      autoload :StructElem, "pdfrb/model/type/struct_elem"

      # Additional base types (previously loaded via require in pdfrb.rb;
      # now autoloaded per project rule).
      autoload :MarkInformation, "pdfrb/model/type/mark_information"
      autoload :IconFit, "pdfrb/model/type/icon_fit"
      autoload :PageLabel, "pdfrb/model/type/page_label"
      autoload :BorderStyling, "pdfrb/model/type/border_styling"
      autoload :BorderEffect, "pdfrb/model/type/border_effect"
      autoload :LineEndingStyling, "pdfrb/model/type/line_ending_styling"
      autoload :InteriorColor, "pdfrb/model/type/interior_color"
      autoload :ObjectReference, "pdfrb/model/type/object_reference"
      autoload :Namespace, "pdfrb/model/type/namespace"
      autoload :SquareCircle, "pdfrb/model/type/square_circle"
      autoload :VariableTextField, "pdfrb/model/type/variable_text_field"
      autoload :DocumentSecurityStore, "pdfrb/model/type/document_security_store"
      autoload :Measure, "pdfrb/model/type/measure"
      autoload :GeospatialMeasure, "pdfrb/model/type/measure"
      autoload :OptionalContentConfiguration, "pdfrb/model/type/optional_content_config"
      autoload :MarkedContentReference, "pdfrb/model/type/marked_content_reference"
      autoload :AppearanceGenerator, "pdfrb/model/type/appearance_generator"
      autoload :Field, "pdfrb/model/type/form_field"
      autoload :TextField, "pdfrb/model/type/text_field"
      autoload :Button, "pdfrb/model/type/button"
      autoload :CheckboxButton, "pdfrb/model/type/button"
      autoload :PushButton, "pdfrb/model/type/button"
      autoload :RadioButton, "pdfrb/model/type/button"
      autoload :Choice, "pdfrb/model/type/choice"
      autoload :SignatureField, "pdfrb/model/type/signature_field"
      autoload :ViewerPreferences, "pdfrb/model/type/viewer_preferences"
      autoload :FontMultipleMaster, "pdfrb/model/type/font_multiple_master"
      autoload :CharProcMap, "pdfrb/model/type/font_multiple_master"
      autoload :FontEncoding, "pdfrb/model/type/font_encoding"
      autoload :CIDFontDescriptorMetrics, "pdfrb/model/type/cid_font_descriptor_metrics"
      autoload :FontCIDType0, "pdfrb/model/type/font_cid_type0"
      autoload :FontCIDType2, "pdfrb/model/type/font_cid_type2"
      autoload :FontDescriptorCIDType0, "pdfrb/model/type/font_descriptor_cid_type0"
      autoload :FontDescriptorCIDType2, "pdfrb/model/type/font_descriptor_cid_type2"
      autoload :ToUnicodeCMapStream, "pdfrb/model/type/to_unicode_cmap_stream"
      autoload :XObjectForm, "pdfrb/model/type/xobject_form"
      autoload :XObjectFormPS, "pdfrb/model/type/xobject_form"
      autoload :XObjectFormPSpassthrough, "pdfrb/model/type/xobject_form"
      autoload :XObjectFormPrinterMark, "pdfrb/model/type/xobject_form"
      autoload :XObjectFormTrapNet, "pdfrb/model/type/xobject_form"
      autoload :XObjectMap, "pdfrb/model/type/xobject_form"
      autoload :XObjectImageMask, "pdfrb/model/type/xobject_image"
      autoload :XObjectImageSoftMask, "pdfrb/model/type/xobject_image"
      autoload :FontFile3Type1, "pdfrb/model/type/font_file3"
      autoload :FontFile3CIDType0, "pdfrb/model/type/font_file3"
      autoload :FontFile3OpenType, "pdfrb/model/type/font_file3"
      autoload :FontDescriptorTrueType, "pdfrb/model/type/font_descriptor"
      autoload :FontDescriptorType3, "pdfrb/model/type/font_descriptor"
      autoload :SoftMaskAlpha, "pdfrb/model/type/soft_mask"
      autoload :SoftMaskLuminosity, "pdfrb/model/type/soft_mask"
      autoload :GraphicsStateParameterMap, "pdfrb/model/type/soft_mask"
      autoload :GroupAttributes, "pdfrb/model/type/soft_mask"
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
      autoload :PatternMap, "pdfrb/model/type/pattern"

      # Shading family (s8.7.4).
      autoload :ShadingCommon, "pdfrb/model/type/shading"
      autoload :Shading, "pdfrb/model/type/shading"
      autoload :ShadingType1, "pdfrb/model/type/shading"
      autoload :ShadingType2, "pdfrb/model/type/shading"
      autoload :ShadingType3, "pdfrb/model/type/shading"
      autoload :ShadingType4, "pdfrb/model/type/shading"
      autoload :ShadingType5, "pdfrb/model/type/shading"
      autoload :ShadingType6, "pdfrb/model/type/shading"
      autoload :ShadingType7, "pdfrb/model/type/shading"
      autoload :ShadingMap, "pdfrb/model/type/shading"

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
      autoload :ThreeDAnnotation, "pdfrb/model/type/three_d_annotation"
      autoload :MovieAnnotation, "pdfrb/model/type/movie_annotation"
      autoload :ProjectionAnnotation, "pdfrb/model/type/projection_annotation"
      autoload :TrapNetworkAnnotation, "pdfrb/model/type/trap_network_annotation"

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
      autoload :ActionGoToE, "pdfrb/model/type/action_go_to_e"
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
      autoload :RenditionMedia, "pdfrb/model/type/rendition"
      autoload :RenditionSelector, "pdfrb/model/type/rendition"
      autoload :RenditionMH, "pdfrb/model/type/rendition"
      autoload :RenditionBE, "pdfrb/model/type/rendition"
      autoload :MediaClipDataMHBE, "pdfrb/model/type/media_clip"
      autoload :MediaClipSection, "pdfrb/model/type/media_clip"
      autoload :MediaClipSectionMHBE, "pdfrb/model/type/media_clip"
      autoload :MediaDuration, "pdfrb/model/type/media_clip"
      autoload :MediaPermissions, "pdfrb/model/type/media_clip"
      autoload :MediaPlayParameters, "pdfrb/model/type/media_offset"
      autoload :MediaPlayParametersMH, "pdfrb/model/type/media_offset"
      autoload :MediaPlayParametersBE, "pdfrb/model/type/media_offset"
      autoload :MediaScreenParametersMHBE, "pdfrb/model/type/media_offset"
      autoload :ExDataProjection, "pdfrb/model/type/projection_annotation"
      autoload :AnnotationProjectionDict, "pdfrb/model/type/projection_annotation"

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
      autoload :DestOutputProfile, "pdfrb/model/type/misc_helpers"
      autoload :OutputIntentsContainer, "pdfrb/model/type/misc_helpers"
      autoload :CMapStream, "pdfrb/model/type/misc_helpers"
      autoload :GammaArray, "pdfrb/model/type/misc_helpers"
      autoload :WhitepointArray, "pdfrb/model/type/misc_helpers"
      autoload :TrailerIDArray, "pdfrb/model/type/misc_helpers"
      autoload :VisibilityExpressionArray, "pdfrb/model/type/misc_helpers"
      autoload :RelatedFilesArray, "pdfrb/model/type/misc_helpers"
      autoload :RichMediaCommandArray, "pdfrb/model/type/misc_helpers"
      autoload :URTransformParamArray, "pdfrb/model/type/misc_helpers"
      autoload :URTransformParamAnnotsArray, "pdfrb/model/type/misc_helpers"
      autoload :URTransformParamEFArray, "pdfrb/model/type/misc_helpers"
      autoload :URTransformParamFormArray, "pdfrb/model/type/misc_helpers"
      autoload :URTransformParamSignatureArray, "pdfrb/model/type/misc_helpers"
      autoload :UniversalArray, "pdfrb/model/type/misc_helpers"
      autoload :UniversalDictionary, "pdfrb/model/type/misc_helpers"
      autoload :OOAdditionalStmsArray, "pdfrb/model/type/misc_helpers"

      # Stream filter /DecodeParms dictionaries (s7.4).
      autoload :FlateDecodeParms, "pdfrb/model/type/filter_decode_parms"
      autoload :LZWDecodeParms, "pdfrb/model/type/filter_decode_parms"
      autoload :DCTDecodeParms, "pdfrb/model/type/filter_decode_parms"
      autoload :CCITTFaxDecodeParms, "pdfrb/model/type/filter_decode_parms"
      autoload :JBIG2DecodeParms, "pdfrb/model/type/filter_decode_parms"
      autoload :CryptDecodeParms, "pdfrb/model/type/filter_decode_parms"

      # Explicit destination arrays + maps (s12.3.2).
      autoload :Destination, "pdfrb/model/type/destination"
      autoload :DestinationXYZ, "pdfrb/model/type/destination"
      autoload :DestinationFit, "pdfrb/model/type/destination"
      autoload :DestinationFitH, "pdfrb/model/type/destination"
      autoload :DestinationFitR, "pdfrb/model/type/destination"
      autoload :DestinationXYZStruct, "pdfrb/model/type/destination"
      autoload :DestinationFitStruct, "pdfrb/model/type/destination"
      autoload :DestinationFitHStruct, "pdfrb/model/type/destination"
      autoload :DestinationFitRStruct, "pdfrb/model/type/destination"
      autoload :DestinationDict, "pdfrb/model/type/destination"
      autoload :DestsMap, "pdfrb/model/type/destination"

      # Array-form color spaces + maps (s8.6).
      autoload :ColorSpace, "pdfrb/model/type/color_space"
      autoload :CalGrayColorSpace, "pdfrb/model/type/color_space"
      autoload :CalRGBColorSpace, "pdfrb/model/type/color_space"
      autoload :LabColorSpace, "pdfrb/model/type/color_space"
      autoload :DeviceGrayColorSpace, "pdfrb/model/type/color_space"
      autoload :DeviceRGBColorSpace, "pdfrb/model/type/color_space"
      autoload :DeviceCMYKColorSpace, "pdfrb/model/type/color_space"
      autoload :ICCBasedColorSpaceArray, "pdfrb/model/type/color_space"
      autoload :IndexedColorSpace, "pdfrb/model/type/color_space"
      autoload :SeparationColorSpace, "pdfrb/model/type/color_space"
      autoload :DeviceNColorSpace, "pdfrb/model/type/color_space"
      autoload :PatternColorSpace, "pdfrb/model/type/color_space"
      autoload :BlackpointArray, "pdfrb/model/type/color_space"
      autoload :ColorSpaceMap, "pdfrb/model/type/color_space"
      autoload :ColorantsDict, "pdfrb/model/type/color_space"
      autoload :BoxStyle, "pdfrb/model/type/color_space"

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
      autoload :CollectionColors, "pdfrb/model/type/collection_colors"
      autoload :CollectionFolder, "pdfrb/model/type/collection_folder"
      autoload :CollectionSplit, "pdfrb/model/type/collection_split"
      autoload :CollectionSubitem, "pdfrb/model/type/collection_subitem"

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
      autoload :CheckboxButton, "pdfrb/model/type/button"
      autoload :PushButton, "pdfrb/model/type/button"
      autoload :RadioButton, "pdfrb/model/type/button"
      autoload :Choice, "pdfrb/model/type/choice"
      autoload :SignatureField, "pdfrb/model/type/signature_field"

      # Structure types (s14.7).
      autoload :StructureAttributes, "pdfrb/model/type/structure_attributes"
      autoload :StructureElementKid, "pdfrb/model/type/structure_element_kid"

      # Page-piece dictionary (s14.5).
      autoload :PagePieceInfo, "pdfrb/model/type/page_piece_info"

      # PAdES validation-related information (ETSI EN 319 142-1).
      autoload :Vri, "pdfrb/model/type/vri"

      # Page thumbnails (s12.3.4).
      autoload :Thumbnail, "pdfrb/model/type/thumbnail"

      # Timespan (s12.7.11, PDF 1.5+).
      autoload :Timespan, "pdfrb/model/type/timespan"

      # Viewport (s12.7.11, PDF 1.6+).
      autoload :Viewport, "pdfrb/model/type/viewport"

      # User property (s14.7.5).
      autoload :UserProperty, "pdfrb/model/type/user_property"

      # Threads/articles (s12.4).
      autoload :Thread, "pdfrb/model/type/thread"
      autoload :Bead, "pdfrb/model/type/bead"

      # Web Capture / spider (s14.10, PDF 1.3, deprecated 2.0).
      autoload :WebCaptureInfo, "pdfrb/model/type/web_capture_page_set"
      autoload :WebCaptureCommand, "pdfrb/model/type/web_capture_command"
      autoload :WebCaptureCommandSettings, "pdfrb/model/type/web_capture_command_settings"
      autoload :WebCaptureImageSet, "pdfrb/model/type/web_capture_image_set"
      autoload :WebCapturePageSet, "pdfrb/model/type/web_capture_page_set"

      # Trapping (Adobe TechNote 5620).
      autoload :TrapRegion, "pdfrb/model/type/trap_region"

      # Additional actions on the Catalog (s12.6.3.17).
      autoload :AddActionCatalog, "pdfrb/model/type/add_action_catalog"

      # Alternate image (s8.9.5).
      autoload :AlternateImage, "pdfrb/model/type/alternate_image"

      # Sound action (s12.6.4.11, deprecated 2.0).
      autoload :ActionSound, "pdfrb/model/type/action_sound"

      # Document Security Store (ETSI EN 319 142-1 PAdES).
      autoload :Dss, "pdfrb/model/type/dss"

      # Document Part hierarchy (ISO 16612-2 PDF/VT).
      autoload :DPartRoot, "pdfrb/model/type/d_part"
      autoload :DPart, "pdfrb/model/type/d_part"

      # Additional actions on page objects (s12.6.3.16).
      autoload :AddActionPageObject, "pdfrb/model/type/add_action_page_object"

      # Additional actions on form fields / screen + widget annotations
      # (s12.6.3.17).
      autoload :AddActionFormField, "pdfrb/model/type/add_action_form_field"
      autoload :AddActionScreenAnnotation, "pdfrb/model/type/add_action_screen_annotation"
      autoload :AddActionWidgetAnnotation, "pdfrb/model/type/add_action_widget_annotation"

      # Final misc tail (streams, launches, media criteria, provenance).
      autoload :EncryptedPayload, "pdfrb/model/type/misc_extras"
      autoload :Permissions, "pdfrb/model/type/misc_extras"
      autoload :FDDict, "pdfrb/model/type/misc_extras"
      autoload :StreamDict, "pdfrb/model/type/misc_extras"
      autoload :DictionaryOfDictionaries, "pdfrb/model/type/misc_extras"
      autoload :DictionaryOfFunctions, "pdfrb/model/type/misc_extras"
      autoload :LinearizationParameterDict, "pdfrb/model/type/misc_extras"
      autoload :FixedPrint, "pdfrb/model/type/misc_extras"
      autoload :FloatingWindowParameters, "pdfrb/model/type/misc_extras"
      autoload :FontFileType1, "pdfrb/model/type/misc_extras"
      autoload :Mac, "pdfrb/model/type/misc_extras"
      autoload :MicrosoftWindowsLaunchParam, "pdfrb/model/type/misc_extras"
      autoload :MinimumBitDepth, "pdfrb/model/type/misc_extras"
      autoload :MinimumScreenSize, "pdfrb/model/type/misc_extras"
      autoload :NavNode, "pdfrb/model/type/misc_extras"
      autoload :Navigator, "pdfrb/model/type/misc_extras"
      autoload :PaperMetaData, "pdfrb/model/type/misc_extras"
      autoload :SlideShow, "pdfrb/model/type/misc_extras"
      autoload :Solidities, "pdfrb/model/type/misc_extras"
      autoload :SourceInformation, "pdfrb/model/type/misc_extras"
      autoload :SpectralData, "pdfrb/model/type/misc_extras"
      autoload :ViewParams, "pdfrb/model/type/misc_extras"
      autoload :DPMMetadataStream, "pdfrb/model/type/misc_extras"
      autoload :Data, "pdfrb/model/type/misc_extras"
      autoload :BeadFirst, "pdfrb/model/type/bead"
      autoload :ThreeDViewAddEntries, "pdfrb/model/type/three_d_view"
      autoload :MovieActivation, "pdfrb/model/type/movie"
      autoload :AppearancePrinterMarkDict, "pdfrb/model/type/printer_mark_annotation"
      autoload :OptContentUsage, "pdfrb/model/type/opt_content_ext"

      # Signature/certification extras + targets + extensions.
      autoload :CertSeedValue, "pdfrb/model/type/signature_extras"
      autoload :SubjectDN, "pdfrb/model/type/signature_extras"
      autoload :DocTimeStamp, "pdfrb/model/type/signature_extras"
      autoload :TimeStampDict, "pdfrb/model/type/signature_extras"
      autoload :AuthCode, "pdfrb/model/type/signature_extras"
      autoload :LegalAttestation, "pdfrb/model/type/signature_extras"
      autoload :VRIMap, "pdfrb/model/type/signature_extras"
      autoload :AFEmbeddedFileParameter, "pdfrb/model/type/signature_extras"
      autoload :AFFileSpecEF, "pdfrb/model/type/signature_extras"
      autoload :Target, "pdfrb/model/type/signature_extras"
      autoload :TargetEmbedded, "pdfrb/model/type/signature_extras"
      autoload :DevExtensions, "pdfrb/model/type/signature_extras"
      autoload :GTSmDevExtensions, "pdfrb/model/type/signature_extras"
      autoload :ISODevExtensions, "pdfrb/model/type/signature_extras"
      autoload :Extensions, "pdfrb/model/type/signature_extras"
      autoload :GTSProcStepsGroup, "pdfrb/model/type/signature_extras"
      autoload :AppleSupplementalText, "pdfrb/model/type/signature_extras"

      # Geospatial support (s11.5) + number formats (s11.4).
      autoload :GeographicCoordinateSystem, "pdfrb/model/type/geospatial"
      autoload :ProjectedCoordinateSystem, "pdfrb/model/type/geospatial"
      autoload :PointData, "pdfrb/model/type/geospatial"
      autoload :Projection, "pdfrb/model/type/geospatial"
      autoload :NumberFormat, "pdfrb/model/type/geospatial"

      # OPI proxy dictionaries (s14.11.6, deprecated 2.0).
      autoload :OPIVersion13Dict, "pdfrb/model/type/opi"
      autoload :OPIVersion20Dict, "pdfrb/model/type/opi"

      # RichMedia sizing/positioning (s13.6.9.5).
      autoload :RichMediaParams, "pdfrb/model/type/rich_media_presentation"
      autoload :RichMediaHeight, "pdfrb/model/type/rich_media_presentation"
      autoload :RichMediaWidth, "pdfrb/model/type/rich_media_presentation"
      autoload :RichMediaPosition, "pdfrb/model/type/rich_media_presentation"

      # Structure tree maps + references (s14.7, s14.8).
      autoload :RoleMap, "pdfrb/model/type/structure_attributes"
      autoload :RoleMapNS, "pdfrb/model/type/structure_attributes"
      autoload :StyleDict, "pdfrb/model/type/structure_attributes"
      autoload :ClassMap, "pdfrb/model/type/structure_attributes"
      autoload :StructureReference, "pdfrb/model/type/structure_attributes"

      # Requirements handlers (s7.9.2, Catalog /Requirements).
      autoload :Requirements3DMarkup, "pdfrb/model/type/requirements"
      autoload :RequirementsAcroFormInteract, "pdfrb/model/type/requirements"
      autoload :RequirementsAction, "pdfrb/model/type/requirements"
      autoload :RequirementsAttachment, "pdfrb/model/type/requirements"
      autoload :RequirementsAttachmentEditing, "pdfrb/model/type/requirements"
      autoload :RequirementsCollection, "pdfrb/model/type/requirements"
      autoload :RequirementsCollectionEditing, "pdfrb/model/type/requirements"
      autoload :RequirementsDPartInteract, "pdfrb/model/type/requirements"
      autoload :RequirementsDigSig, "pdfrb/model/type/requirements"
      autoload :RequirementsDigSigMDP, "pdfrb/model/type/requirements"
      autoload :RequirementsDigSigValidation, "pdfrb/model/type/requirements"
      autoload :RequirementsEnableJavaScripts, "pdfrb/model/type/requirements"
      autoload :RequirementsEncryption, "pdfrb/model/type/requirements"
      autoload :RequirementsGeospatial2D, "pdfrb/model/type/requirements"
      autoload :RequirementsGeospatial3D, "pdfrb/model/type/requirements"
      autoload :RequirementsHandler, "pdfrb/model/type/requirements"
      autoload :RequirementsMarkup, "pdfrb/model/type/requirements"
      autoload :RequirementsMultimedia, "pdfrb/model/type/requirements"
      autoload :RequirementsNavigation, "pdfrb/model/type/requirements"
      autoload :RequirementsOCAutoStates, "pdfrb/model/type/requirements"
      autoload :RequirementsOCInteract, "pdfrb/model/type/requirements"
      autoload :RequirementsPRC, "pdfrb/model/type/requirements"
      autoload :RequirementsRichMedia, "pdfrb/model/type/requirements"
      autoload :RequirementsSTEP, "pdfrb/model/type/requirements"
      autoload :RequirementsSeparationSimulation, "pdfrb/model/type/requirements"
      autoload :RequirementsTransitions, "pdfrb/model/type/requirements"
      autoload :RequirementsU3D, "pdfrb/model/type/requirements"
      autoload :RequirementsglTF, "pdfrb/model/type/requirements"

      # Border style (s12.5.4). BorderEffect lives in its own file.
      autoload :BorderStyle, "pdfrb/model/type/border_style"
      autoload :BorderEffect, "pdfrb/model/type/border_effect"
    end
  end
end
