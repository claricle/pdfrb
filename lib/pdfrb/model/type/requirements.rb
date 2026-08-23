# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Requirements handler dictionary (s7.9.2, Catalog /Requirements).
      # Common keys across every handler: the feature /S, the version
      # /V that introduced it, the reader handler /RH, and the /Penalty
      # for missing support. Feature-specific keys live on subclasses.
      class RequirementsHandler < Pdfrb::Model::Cos::Dictionary
        arlington_object "RequirementsHandler"

        def type; self[:Type]; end
        def feature; self[:S]; end
        def version; self[:V]; end
        def reader_handler; self[:RH]; end
        def penalty; self[:Penalty]; end

        def fatal?
          penalty&.to_sym == :Fatal
        end

        # /Script — JavaScript reader-handler bootstrap.
        def script; self[:Script]; end
      end

      # /Requirements entry (s7.9.2): feature "3DMarkup".
      class Requirements3DMarkup < RequirementsHandler
        arlington_object "Requirements3DMarkup"
      end

      # /Requirements entry (s7.9.2): feature "AcroFormInteract".
      class RequirementsAcroFormInteract < RequirementsHandler
        arlington_object "RequirementsAcroFormInteract"
      end

      # /Requirements entry (s7.9.2): feature "Action".
      class RequirementsAction < RequirementsHandler
        arlington_object "RequirementsAction"
      end

      # /Requirements entry (s7.9.2): feature "Attachment".
      class RequirementsAttachment < RequirementsHandler
        arlington_object "RequirementsAttachment"
      end

      # /Requirements entry (s7.9.2): feature "AttachmentEditing".
      class RequirementsAttachmentEditing < RequirementsHandler
        arlington_object "RequirementsAttachmentEditing"
      end

      # /Requirements entry (s7.9.2): feature "Collection".
      class RequirementsCollection < RequirementsHandler
        arlington_object "RequirementsCollection"
      end

      # /Requirements entry (s7.9.2): feature "CollectionEditing".
      class RequirementsCollectionEditing < RequirementsHandler
        arlington_object "RequirementsCollectionEditing"
      end

      # /Requirements entry (s7.9.2): feature "DPartInteract".
      class RequirementsDPartInteract < RequirementsHandler
        arlington_object "RequirementsDPartInteract"
      end

      # /Requirements entry (s7.9.2): feature "DigSig".
      class RequirementsDigSig < RequirementsHandler
        arlington_object "RequirementsDigSig"

        def dig_sig; self[:DigSig]; end
      end

      # /Requirements entry (s7.9.2): feature "DigSigMDP".
      class RequirementsDigSigMDP < RequirementsHandler
        arlington_object "RequirementsDigSigMDP"

        def dig_sig; self[:DigSig]; end
      end

      # /Requirements entry (s7.9.2): feature "DigSigValidation".
      class RequirementsDigSigValidation < RequirementsHandler
        arlington_object "RequirementsDigSigValidation"

        def dig_sig; self[:DigSig]; end
      end

      # /Requirements entry (s7.9.2): feature "EnableJavaScripts".
      class RequirementsEnableJavaScripts < RequirementsHandler
        arlington_object "RequirementsEnableJavaScripts"
      end

      # /Requirements entry (s7.9.2): feature "Encryption".
      class RequirementsEncryption < RequirementsHandler
        arlington_object "RequirementsEncryption"

        def encrypt_dict; self[:Encrypt]; end
      end

      # /Requirements entry (s7.9.2): feature "Geospatial2D".
      class RequirementsGeospatial2D < RequirementsHandler
        arlington_object "RequirementsGeospatial2D"
      end

      # /Requirements entry (s7.9.2): feature "Geospatial3D".
      class RequirementsGeospatial3D < RequirementsHandler
        arlington_object "RequirementsGeospatial3D"
      end

      # /Requirements entry (s7.9.2): feature "Markup".
      class RequirementsMarkup < RequirementsHandler
        arlington_object "RequirementsMarkup"
      end

      # /Requirements entry (s7.9.2): feature "Multimedia".
      class RequirementsMultimedia < RequirementsHandler
        arlington_object "RequirementsMultimedia"
      end

      # /Requirements entry (s7.9.2): feature "Navigation".
      class RequirementsNavigation < RequirementsHandler
        arlington_object "RequirementsNavigation"
      end

      # /Requirements entry (s7.9.2): feature "OCAutoStates".
      class RequirementsOCAutoStates < RequirementsHandler
        arlington_object "RequirementsOCAutoStates"
      end

      # /Requirements entry (s7.9.2): feature "OCInteract".
      class RequirementsOCInteract < RequirementsHandler
        arlington_object "RequirementsOCInteract"
      end

      # /Requirements entry (s7.9.2): feature "PRC".
      class RequirementsPRC < RequirementsHandler
        arlington_object "RequirementsPRC"
      end

      # /Requirements entry (s7.9.2): feature "RichMedia".
      class RequirementsRichMedia < RequirementsHandler
        arlington_object "RequirementsRichMedia"
      end

      # /Requirements entry (s7.9.2): feature "STEP".
      class RequirementsSTEP < RequirementsHandler
        arlington_object "RequirementsSTEP"
      end

      # /Requirements entry (s7.9.2): feature "SeparationSimulation".
      class RequirementsSeparationSimulation < RequirementsHandler
        arlington_object "RequirementsSeparationSimulation"
      end

      # /Requirements entry (s7.9.2): feature "Transitions".
      class RequirementsTransitions < RequirementsHandler
        arlington_object "RequirementsTransitions"
      end

      # /Requirements entry (s7.9.2): feature "U3D".
      class RequirementsU3D < RequirementsHandler
        arlington_object "RequirementsU3D"
      end

      # /Requirements entry (s7.9.2): feature "glTF".
      class RequirementsglTF < RequirementsHandler
        arlington_object "RequirementsglTF"
      end
    end
  end
end
