# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Optional Content Usage Application dict (s8.11.4.1). Decides
      # which OCGs to enable when the user views/prints/exports the
      # document.
      class OptContentUsageApplication < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentUsageApplication"
        def event; self[:Event]&.to_sym; end
        def ocgs; self[:OCGs]; end
        def category; self[:Category]; end

        def view_event?; event == :View; end
        def print_event?; event == :Print; end
        def export_event?; event == :Export; end

        def each_ocg
          return enum_for(:each_ocg) unless block_given?
          return unless ocgs && document

          arr = ocgs.is_a?(Pdfrb::Model::PdfArray) ? ocgs.to_a : ocgs
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end

      # Optional Content Creator Info dict (s8.11.2.2). Attribution
      # for who created a layer.
      class OptContentCreatorInfo < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentCreatorInfo"
        def creator; self[:Creator]; end
        def subtitle; self[:Subtitle]; end
        def creator_app_version; self[:CreatorAppVersion]; end

        def has_creator?
          !!creator
        end
      end

      # Optional Content Export dict (s8.11.2.3). Specific OCG toggle
      # for the export workflow.
      class OptContentExport < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentExport"
        def export_ocgs; self[:ExportOCGs]; end
        def intent; self[:Intent]&.to_sym; end

        def visible_only?
          intent == :Visible
        end

        def all_export?
          intent == :All
        end
      end

      # Optional Content Print dict (s8.11.2.4). Similar to Export but
      # for the printing workflow.
      class OptContentPrint < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentPrint"
        def print_ocgs; self[:PrintOCGs]; end
        def print_state; self[:PrintState]&.to_sym; end

        def on_printed?; print_state == :On; end
        def off_printed?; print_state == :Off; end
        def leave_unchanged?; print_state == :Unchanged; end
      end

      # Optional Content View dict (s8.11.2.5). Per-view OCG visibility.
      class OptContentView < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentView"
        def view_name; self[:Name]; end
        def view_state_name; self[:ViewState]; end
      end

      # Optional Content Language dict (s8.11.2.6). Maps OCG to natural
      # language for preference-based visibility.
      class OptContentLanguage < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentLanguage"
        def language_string; self[:Lang]; end
        def ocgs; self[:OCGs]; end
        def preferred; self[:Preferred] || 0; end

        def each_ocg
          return enum_for(:each_ocg) unless block_given?
          return unless ocgs && document

          arr = ocgs.is_a?(Pdfrb::Model::PdfArray) ? ocgs.to_a : ocgs
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end

      # /Usage /User entry (s8.11.4.4). Intended consumer of the
      # group.
      class OptContentUser < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentUser"

        def name; self[:Name]; end
      end

      # /Usage /Zoom entry (s8.11.4.4). Zoom-range visibility.
      class OptContentZoom < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentZoom"

        def min; self[:min]; end
        def max; self[:max]; end
      end
    end
  end
end
