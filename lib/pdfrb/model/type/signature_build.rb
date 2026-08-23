# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Signature Build Data Dict (s12.8.4.2, Table 356). Per-PPKLite
      # build-data dict holding filter / PubSec / App / SigQ
      # sub-dictionaries.
      class SignatureBuildDataDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureBuildDataDict"
        def filter; self[:Filter]; end
        def pub_sec; self[:PubSec]; end
        def app; self[:App]; end
        def sig_q; self[:SigQ]; end

        def has_app?
          !!app
        end

        def has_filter?
          !!filter
        end
      end

      # Signature Build Data App Dict (s12.8.4.2). Per-app info.
      class SignatureBuildDataAppDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureBuildDataAppDict"
        def name; self[:Name]; end
        def date; self[:Date]; end
        def r; self[:R]; end
        def pre_release?; truthy?(self[:PreRelease]); end
        def build_type; self[:Type]&.to_sym; end
      end

      # Signature Build Data SigQ Dict (s12.8.4.2). PKCS#7 signing
      # request quality metadata.
      class SignatureBuildDataSigQDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureBuildDataSigQDict"
        def r; self[:R]; end
        def q; self[:Q]; end
        def hash; self[:HashAlgorithm]&.to_sym; end

        def has_quality_flags?
          !!q || !!r
        end
      end

      # Signature Reference DocMDP (s12.8.2.2). DocMDP signature
      # reference.
      class SignatureReferenceDocMDP < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureReferenceDocMDP"
        def type; self[:Type]; end
        def digest_method; self[:DigestMethod]&.to_sym; end

        def rip1?
          type == :DocumentModificationPermissions
        end
      end

      # Signature Reference Identity (s12.8.2.2). Identity signature
      # reference.
      class SignatureReferenceIdentity < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureReferenceIdentity"
        def type; self[:Type]; end
        def digest_method; self[:DigestMethod]&.to_sym; end
      end

      # Signature Reference UR (Usage Rights, s12.8.2.3).
      class SignatureReferenceUR < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureReferenceUR"
        def type; self[:Type]; end
        def digest_method; self[:DigestMethod]&.to_sym; end
        def transform_params; self[:TransformParams]; end

        def resolved_transform_params
          ref = transform_params
          return nil unless ref && document

          document.object(ref)
        end
      end

      # Signature Reference FieldMDP (s12.7.6.5). FieldMDP signature
      # reference.
      class SignatureReferenceFieldMDP < Pdfrb::Model::Cos::Dictionary
        arlington_object "SignatureReferenceFieldMDP"
        def type; self[:Type]; end
        def digest_method; self[:DigestMethod]&.to_sym; end
        def transform_params; self[:TransformParams]; end
      end
    end
  end
end
