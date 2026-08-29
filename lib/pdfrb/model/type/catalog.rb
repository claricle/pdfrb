# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Root of the document object hierarchy (s7.7.2). Linked from
      # the trailer's /Root. Fields: /Type, /Version, /Extensions,
      # /Pages, /PageLabels, /Names, /Dests, /ViewerPreferences,
      # /PageLayout, /PageMode, /Outlines, /Threads, /OpenAction,
      # /AA, /URI, /AcroForm, /Metadata, /StructTreeRoot, /MarkInfo,
      # /Lang, /SpiderInfo, /OutputIntents, /PieceInfo, /OCProperties,
      # /Perms, /Legal, /Requirements, /Collection, /NeedsRendering,
      # /DSS, /AF, /DPartRoot.
      class Catalog < Pdfrb::Model::Cos::Dictionary
        arlington_object "Catalog"
        register_type :Catalog

        def pages; self[:Pages]; end
        def page_labels; self[:PageLabels]; end
        def names; self[:Names]; end
        def destinations; self[:Dests]; end
        def viewer_preferences; self[:ViewerPreferences]; end
        def page_layout; self[:PageLayout]; end
        def page_mode; self[:PageMode]; end
        def outlines; self[:Outlines]; end
        def threads; self[:Threads]; end
        def open_action; self[:OpenAction]; end
        def additional_actions; self[:AA]; end
        def uri; self[:URI]; end
        def acro_form; self[:AcroForm]; end
        def metadata; self[:Metadata]; end
        def struct_tree_root; self[:StructTreeRoot]; end
        def mark_info; self[:MarkInfo]; end
        def lang; self[:Lang]; end
        def spider_info; self[:SpiderInfo]; end
        def output_intents; self[:OutputIntents]; end
        def piece_info; self[:PieceInfo]; end
        def oc_properties; self[:OCProperties]; end
        def perms; self[:Perms]; end
        def legal; self[:Legal]; end
        def requirements; self[:Requirements]; end
        def collection; self[:Collection]; end
        def needs_rendering?; truthy?(self[:NeedsRendering]); end
        def dss; self[:DSS]; end
        def associated_files; self[:AF]; end
        def dpart_root; self[:DPartRoot]; end
        def version_override; self[:Version]; end
        def extensions; self[:Extensions]; end

        def single_page_layout?; page_layout&.to_sym == :SinglePage; end
        def one_column_layout?; page_layout&.to_sym == :OneColumn; end

        def two_column_layout?
          [:TwoColumnLeft, :TwoColumnRight].include?(page_layout&.to_sym)
        end

        def two_page_layout?
          [:TwoPageLeft, :TwoPageRight].include?(page_layout&.to_sym)
        end

        def use_attachments_mode?; page_mode&.to_sym == :UseAttachments; end
        def use_thumbs_mode?; page_mode&.to_sym == :UseThumbs; end
        def use_outlines_mode?; page_mode&.to_sym == :UseOutlines; end
        def full_screen_mode?; page_mode&.to_sym == :FullScreen; end
        def use_oc_mode?; page_mode&.to_sym == :UseOC; end

        def tagged?
          mark_info && !!mark_info[:Marked]
        end

        def contains_struct_tree?
          !!struct_tree_root
        end

        def contains_form?
          !!acro_form
        end

        def contains_outlines?
          !!outlines
        end

        def page_count
          return 0 unless pages

          obj = pages.is_a?(Pdfrb::Model::Reference) && document ? document.object(pages) : pages
          obj && obj[:Count]
        end

        def resolved_pages
          return nil unless pages && document

          document.object(pages)
        end

        def resolved_acro_form
          return nil unless acro_form && document

          document.object(acro_form)
        end

        def resolved_outlines
          return nil unless outlines && document

          document.object(outlines)
        end

        def resolved_metadata
          return nil unless metadata && document

          document.object(metadata)
        end

        def each_output_intent
          return enum_for(:each_output_intent) unless block_given?
          return unless output_intents && document

          arr = if output_intents.is_a?(Pdfrb::Model::Reference)
                  document.object(output_intents)
                else
                  output_intents
                end
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |entry|
            obj = document.resolve(entry)
            yield obj if obj
          end
        end
      end
    end
  end
end
