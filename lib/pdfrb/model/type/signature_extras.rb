# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Certificate seed-value dictionary (s12.7.4.5.2, /SV /Cert):
      # constrains the signing certificate (subject, policies, usage).
      class CertSeedValue < Pdfrb::Model::Cos::Dictionary
        arlington_object "CertSeedValue"

        def flags; self[:Ff]; end
        def subject; self[:Subject]; end
        def subject_dn; self[:SubjectDN]; end
        def key_usage; self[:KeyUsage]; end
        def issuer; self[:Issuer]; end
        def oid; self[:OID]; end
        def url; self[:URL]; end
        def url_type; self[:URLType]; end
        def signature_policy_oid; self[:SignaturePolicyOID]; end
        def signature_policy_hash; self[:SignaturePolicyHashValue]; end
      end

      # Subject distinguished-name sub-dictionary (s12.7.4.5.2):
      # keyed by DN component (CN, O, C, ...).
      class SubjectDN < Pdfrb::Model::Cos::Dictionary
        arlington_object "SubjectDN"

        def [](component)
          value[component.to_sym] || value[component.to_s]
        end

        def components
          value.keys
        end
      end

      # Document timestamp signature (s12.8.1, /DocTimeStamp): an
      # RFC 3161 timestamp applied as a signature.
      class DocTimeStamp < Pdfrb::Model::Cos::Dictionary
        arlington_object "DocTimeStamp"

        def type; self[:Type]; end
        def filter; self[:Filter]; end
        def subfilter; self[:SubFilter]; end
        def contents; self[:Contents]; end
        def byte_range; self[:ByteRange]; end
        def reference; self[:Reference]; end
        def changes; self[:Changes]; end
        def reason; self[:Reason]; end
        def contact_info; self[:ContactInfo]; end
      end

      # Time-stamp dictionary (s12.8.3.5): URL for RFC 3161 servers.
      class TimeStampDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "TimeStampDict"

        def url; self[:URL]; end
        def flags; self[:Ff]; end
      end

      # Author-specified adobe-style authorization code data for
      # cryptographic signatures.
      class AuthCode < Pdfrb::Model::Cos::Dictionary
        arlington_object "AuthCode"

        def mac_location; self[:MACLocation]; end
        def byte_range; self[:ByteRange]; end
        def mac; self[:MAC]; end
        def signature_object_ref; self[:SigObjRef]; end
      end

      # Legal attestation dictionary (s7.12.4, Catalog /Legal
      # /Attestation): per-feature compliance flags for PDF/A-style
      # legal attestation.
      class LegalAttestation < Pdfrb::Model::Cos::Dictionary
        arlington_object "LegalAttestation"

        def javascript_actions; self[:JavaScriptActions]; end
        def launch_actions; self[:LaunchActions]; end
        def uri_actions; self[:URIActions]; end
        def non_embedded_fonts; self[:NonEmbeddedFonts]; end
        def annotations; self[:Annotations]; end
        def optional_content; self[:OptionalContent]; end
        def attestation; self[:Attestation]; end
      end

      # VRI map (ETSI EN 319 142-1, DSS /VRI): hash-of-signature ->
      # validation data for one signature.
      class VRIMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "VRIMap"

        def [](signature_hash)
          value[signature_hash.to_sym] || value[signature_hash.to_s]
        end

        def signature_hashes
          value.keys
        end
      end

      # Associated-file embedded-file parameters (PDF 2.0 App Note
      # 002, /AFParameter): Size, dates, /Mac sub-dict, CheckSum.
      class AFEmbeddedFileParameter < Pdfrb::Model::Cos::Dictionary
        arlington_object "AFEmbeddedFileParameter"

        def size; self[:Size]; end
        def creation_date; self[:CreationDate]; end
        def mod_date; self[:ModDate]; end
        def mac; self[:Mac]; end
        def checksum; self[:CheckSum]; end
      end

      # Associated-file EF map (App Note 002, /AF): F/UF name and
      # unicode file-spec entries.
      class AFFileSpecEF < Pdfrb::Model::Cos::Dictionary
        arlington_object "AFFileSpecEF"

        def f; self[:F]; end
        def uf; self[:UF]; end
      end

      # GoToE target dictionary (s12.3.2.5, /T): locates the file and
      # position for an embedded navigation target.
      class Target < Pdfrb::Model::Cos::Dictionary
        arlington_object "Target"

        def relation; self[:R]; end
        def file_name; self[:N]; end
        def page; self[:P]; end
        def attached_file; self[:A]; end
        def nested_target; self[:T]; end

        def parent_relation?; relation == :P; end
        def child_relation?; relation == :C; end
      end

      # Embedded target (s12.3.2.5): the embedded variant of Target.
      class TargetEmbedded < Target
        arlington_object "TargetEmbedded"
      end

      # Developer extensions dictionary (s7.2, Catalog /Extensions):
      # developer-identified extensions to the base spec.
      class DevExtensions < Pdfrb::Model::Cos::Dictionary
        arlington_object "DevExtensions"

        def type; self[:Type]; end
        def base_version; self[:BaseVersion]; end
        def extension_level; self[:ExtensionLevel]; end
        def url; self[:URL]; end
        def extension_revision; self[:ExtensionRevision]; end
      end

      # GTSm (Global Graphics) developer extension entry.
      class GTSmDevExtensions < DevExtensions
        arlington_object "GTSm_DevExtensions"
      end

      # ISO developer extension entry.
      class ISODevExtensions < DevExtensions
        arlington_object "ISO_DevExtensions"
      end

      # Extension level container (s7.2, /Extensions value): maps
      # developer names to their DevExtensions entries.
      class Extensions < Pdfrb::Model::Cos::Dictionary
        arlington_object "Extensions"

        def [](developer)
          value[developer.to_sym] || value[developer.to_s]
        end

        def developers
          value.keys
        end
      end

      # GTS Procedural Steps group (prepress): identifies a
      # processing step region on a page.
      class GTSProcStepsGroup < Pdfrb::Model::Cos::Dictionary
        arlington_object "GTS_ProcStepsGroup"

        def group; self[:GTS_ProcStepsGroup]; end
        def step_type; self[:GTS_ProcStepsType]; end
        def colorants; self[:GTS_ProcStepsColorants]; end
      end

      # Apple supplemental-text entry (AAPL_ST): supplemental text
      # positioning data used by macOS previews.
      class AppleSupplementalText < Pdfrb::Model::Cos::Dictionary
        arlington_object "AAPL_ST"

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def offset; self[:Offset]; end
        def radius; self[:Radius]; end
        def color_space; self[:ColorSpace]; end
        def color; self[:Color]; end
      end
    end
  end
end
