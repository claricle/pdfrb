# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Encrypted payload dictionary (s7.11.4.1, /Encrypt on an
      # embedded file's /EF entry): identifies the encryption applied
      # to the file's bytes.
      class EncryptedPayload < Pdfrb::Model::Cos::Dictionary
        arlington_object "EncryptedPayload"

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def version; self[:Version]; end
      end

      # Permissions dictionary (s12.8.4): signature-transform
      # permissions for /DocMDP and /UR3 entries.
      class Permissions < Pdfrb::Model::Cos::Dictionary
        arlington_object "Permissions"

        def doc_mdp; self[:DocMDP]; end
        def ur3; self[:UR3]; end
      end

      # FDF dictionary (s12.7.8, /FDF): form-data root inside an FDF
      # file. Keys vary by tool; the map is open.
      class FDDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "FDDict"
      end

      # Base stream dictionary (s7.3.8.2, /Length /Filter ...):
      # applied to every stream that carries no more specific Type.
      class StreamDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "Stream"

        def length; self[:Length]; end
        def filter; self[:Filter]; end
        def decode_parms; self[:DecodeParms]; end
        def file_spec; self[:F]; end
        def file_filter; self[:FFilter]; end
        def file_decode_parms; self[:FDecodeParms]; end
        def dl; self[:DL]; end
      end

      # Dictionary of dictionaries (Arlington helper): wildcard map
      # whose values are dictionaries.
      class DictionaryOfDictionaries < Pdfrb::Model::Cos::Dictionary
        arlington_object "DictionaryOfDictionaries"
      end

      # Dictionary of functions (s10.4, stitching /Functions entry):
      # wildcard map of name -> function.
      class DictionaryOfFunctions < Pdfrb::Model::Cos::Dictionary
        arlington_object "DictionaryOfFunctions"

        def default_function; self[:Default]; end
      end

      # Linearization parameter dictionary (s7.5.8.2, first-page
      # object /Linearized dict).
      class LinearizationParameterDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "LinearizationParameterDict"

        def linearized; self[:Linearized]; end
        def file_length; self[:L]; end
        def first_page_offset; self[:H]; end
        def offset_of_first_page_end; self[:O]; end
        def offset_of_last_page_end; self[:E]; end
        def page_count; self[:N]; end
        def xref_table_offset; self[:T]; end
        def offset_of_main_xref; self[:P]; end
      end

      # Fixed-print dictionary (s12.7.4.5.4, /AP /FixedPrint):
      # watermark placement and scaling.
      class FixedPrint < Pdfrb::Model::Cos::Dictionary
        arlington_object "FixedPrint"

        def type; self[:Type]; end
        def matrix; self[:Matrix]; end
        def horizontal_adjustment; self[:H]; end
        def vertical_adjustment; self[:V]; end
      end

      # Floating-window parameters (s13.2.2 media /F): presentation
      # mode with duration, opacity, and resize behaviour.
      class FloatingWindowParameters < Pdfrb::Model::Cos::Dictionary
        arlington_object "FloatingWindowParameters"

        def type; self[:Type]; end
        def default_visible; self[:D]; end
        def resize_type; self[:RT]; end
        def has_title_bar?; self[:P]; end
        def has_close_button?; self[:O]; end
        def title; self[:T]; end
        def ui_constrained?; self[:UC]; end

        # /R defaults to 0 (not resizable) via the TSV.
        def resizable?
          !self[:R].nil? && self[:R] != 0 && self[:R] != false
        end
      end

      # FontFileType1 (s9.6.6.2): the Type 1 /FontFile stream keys.
      class FontFileType1 < Pdfrb::Model::Cos::Stream
        arlington_object "FontFileType1"

        def clear_text_length; self[:Length1]; end
        def encrypted_length; self[:Length2]; end
        def trailer_length; self[:Length3]; end
      end

      # Mac OS file descriptor (s7.11.4.5, /Mac): resource-fork and
      # creator info for platform-specific embedding.
      class Mac < Pdfrb::Model::Cos::Dictionary
        arlington_object "Mac"

        def subtype; self[:Subtype]; end
        def creator; self[:Creator]; end
        def res_fork; self[:ResFork]; end
      end

      # Windows launch parameter dictionary (s12.6.4.6, /Win): the
      # Windows half of a /Launch action.
      class MicrosoftWindowsLaunchParam < Pdfrb::Model::Cos::Dictionary
        arlington_object "MicrosoftWindowsLaunchParam"

        def file; self[:F]; end
        def default_directory; self[:D]; end
        def operation; self[:O]; end
        def parameters; self[:P]; end
      end

      # Minimum bit depth (s13.2 media criteria /D /Bits): colour
      # depth the viewer must support.
      class MinimumBitDepth < Pdfrb::Model::Cos::Dictionary
        arlington_object "MinimumBitDepth"

        def type; self[:Type]; end
        def value; self[:V]; end
        def minimum_screen; self[:M]; end
      end

      # Minimum screen size (s13.2 media criteria /D /Sys).
      class MinimumScreenSize < Pdfrb::Model::Cos::Dictionary
        arlington_object "MinimumScreenSize"

        def type; self[:Type]; end
        def value; self[:V]; end
        def minimum_screen; self[:M]; end
      end

      # Navigator node (s7.11.5.2, collections /NavNode): one node
      # in a portfolio navigation flow.
      class NavNode < Pdfrb::Model::Cos::Dictionary
        arlington_object "NavNode"

        def type; self[:Type]; end
        def next_action; self[:NA]; end
        def previous_action; self[:PA]; end
        def next_node; self[:Next]; end
        def previous_node; self[:Prev]; end
        def duration; self[:Dur]; end
      end

      # Navigator (s7.11.5.2, collections /Navigator): a Flash or
      # static layout describing portfolio navigation.
      class Navigator < Pdfrb::Model::Cos::Dictionary
        arlington_object "Navigator"

        def type; self[:Type]; end
        def layout; self[:Layout]; end
        def flash; self[:SWF]; end
        def name; self[:Name]; end
        def description; self[:Desc]; end
        def category; self[:Category]; end
        def id; self[:ID]; end
        def version; self[:Version]; end
      end

      # Paper metadata (s7.11.5.3, /Paper): barcode/paper-form data.
      class PaperMetaData < Pdfrb::Model::Cos::Dictionary
        arlington_object "PaperMetaData"

        def type; self[:Type]; end
        def version; self[:Version]; end
        def resolution; self[:Resolution]; end
        def caption; self[:Caption]; end
        def symbology; self[:Symbology]; end
        def width; self[:Width]; end
        def height; self[:Height]; end
        def xsym_width; self[:XSymWidth]; end
      end

      # Slide-show dictionary (s13.5.2, /SlideShow): a sequence of
      # pages or resources for presentation mode.
      class SlideShow < Pdfrb::Model::Cos::Dictionary
        arlington_object "SlideShow"

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def resources; self[:Resources]; end
        def start_resource; self[:StartResource]; end
      end

      # Solidities map (DeviceN /MixingHints /Solidities):
      # colorant name -> ink solidity percentage.
      class Solidities < Pdfrb::Model::Cos::Dictionary
        arlington_object "Solidities"

        def [](colorant)
          value[colorant.to_sym] || value[colorant.to_s]
        end

        def colorant_names
          value.keys
        end
      end

      # Source information (s14.10.2, /SourceInfo): provenance for
      # structure elements.
      class SourceInformation < Pdfrb::Model::Cos::Dictionary
        arlington_object "SourceInformation"

        def author; self[:AU]; end
        def timestamp; self[:TS]; end
        def engine; self[:E]; end
        def description; self[:S]; end
        def color; self[:C]; end
      end

      # Spectral data (DeviceN /Subtype /NChannel colorants):
      # per-colorant spectral measurement maps.
      class SpectralData < Pdfrb::Model::Cos::Dictionary
        arlington_object "SpectralData"
      end

      # View parameters (s13.6.2.4, 3D /VA array entries): per-frame
      # view + animation data.
      class ViewParams < Pdfrb::Model::Cos::Dictionary
        arlington_object "ViewParams"

        def instance; self[:Instance]; end
        def data; self[:Data]; end
      end

      # DPM metadata stream dictionary (PDF 2.0 App Note 003,
      # /Type /Metadata /Subtype /DPM): document-part metadata.
      class DPMMetadataStream < Pdfrb::Model::Cos::Dictionary
        arlington_object "DPM"

        def gts_managed; self[:GTS_Managed]; end
        def gts_suspect; self[:GTS_Suspect]; end
        def cip4_root; self[:CIP4_Root]; end
      end

      # Private data dictionary (s14.10 /Data): application-private
      # provenance payloads.
      class Data < Pdfrb::Model::Cos::Dictionary
        arlington_object "Data"

        def last_modified; self[:LastModified]; end
        def private_data; self[:Private]; end
      end
    end
  end
end
