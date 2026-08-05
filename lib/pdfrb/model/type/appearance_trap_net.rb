# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # AppearanceTrapNet sub-dictionary (s7.7.3.3, Table 327). Per-
      # appearance-stream trap-net (ink-flattening) parameters.
      class AppearanceTrapNetSubDict < Pdfrb::Model::Cos::Dictionary
        def pos_h; self[:PosH]; end
        def pos_l; self[:PosL]; end
        def span_h_min; self[:SpanH]; end
        def span_l_min; self[:SpanL]; end
        def font_info; self[:FontInfo]; end

        def has_darkness_corrected?
          !!font_info
        end
      end

      # AppearanceTrapNet (s7.7.3.3). The trap-net dictionary that wraps
      # appearance sub-dicts.
      class AppearanceTrapNet < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def version; self[:Version]; end
        def font_state_appearance; self[:FontStateAppearance]; end
        def gray_min; self[:GrayMin]; end
        def gray_max; self[:GrayMax]; end
        def monochrome_min; self[:MonoMin]; end
        def monochrome_max; self[:MonoMax]; end
        def colorant_min; self[:ColorantMin]; end
        def colorant_max; self[:ColorantMax]; end
        def step_function; self[:StepFunction]; end
        def trap_net_app_form_name; self[:AppForm]; end

        def has_step_function?
          !!step_function
        end
      end

      # AppearanceSubDict (s12.5.4). Sub-dictionary inside Appearance
      # entries /N, /R, /D that maps each appearance state to a stream.
      class AppearanceSubDict < Pdfrb::Model::Cos::Dictionary
        def each_state(&block)
          return enum_for(:each_state) unless block

          value.each(&block)
        end

        def state_count
          value.size
        end

        def states
          value.keys
        end
      end

      # Signature Build Data Dict (s12.8.4). PPKLite build data.
      class SignatureBuildPropDict < Pdfrb::Model::Cos::Dictionary
        def app_build; self[:App]; end

        def has_app_build?
          !!app_build
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
