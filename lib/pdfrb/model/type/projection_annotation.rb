# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Projection annotation (s12.5.6.19, PDF 1.7+AdobeExt). Projects
      # a duplicate of a region of a page with a modified appearance.
      class ProjectionAnnotation < MarkupAnnotation
        arlington_object "AnnotProjection"

        def title; self[:T]; end
        def popup; self[:Popup]; end
        def rich_contents; self[:RC]; end
        def creation_date; self[:CreationDate]; end
        def in_reply_to; self[:IRT]; end
        def subject; self[:Subj]; end
        def reply_type; self[:RT]; end
        def intent; self[:IT]; end
        def ex_data; self[:ExData]; end

        def has_projection_data?
          !ex_data.nil?
        end
      end

      # Annotation Projection dict (s12.5.6.21). Projection annotation
      # for spatial content.
      class AnnotationProjectionDict < Pdfrb::Model::Cos::Dictionary
        def ex_data; self[:ExData]; end
      end

      # ExData Projection dict (s12.5.6.21, Table 198). Holds the
      # geospatial projection details used by Projection annotations.
      class ExDataProjection < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end

        def project?
          type == :ProjectedPDL
        end
      end
    end
  end
end
