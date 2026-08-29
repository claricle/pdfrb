# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Page object (s7.7.3.3). Fields: /Type, /Parent, /LastModified,
      # /Resources, /MediaBox, /CropBox, /BleedBox, /TrimBox, /ArtBox,
      # /BoxColorInfo, /Contents, /Rotate, /Group, /Thumb, /B, /Dur,
      # /Trans, /Annots, /AA, /Metadata, /PieceInfo, /StructParents,
      # /ID, /PZ, /SeparationInfo, /Tabs, /TemplateInstantiated,
      # /PresSteps, /UserUnit, /VP, /AF, /OutputIntents, /DPart.
      class Page < Pdfrb::Model::Cos::Dictionary
        arlington_object "PageObject"
        register_type :Page

        # Returns a +Content::Canvas+ bound to this page's /Contents
        # stream. Auto-creates a Contents stream if the page has
        # none. Memoised per page instance.
        def canvas
          @canvas ||= begin
            ref = value[:Contents]
            stream =
              if ref.nil?
                new_stream = document.add({}, type: Pdfrb::Model::Cos::Stream)
                new_stream.stream = ""
                value[:Contents] = new_stream.ref
                new_stream
              else
                document.resolve(ref)
              end
            Pdfrb::Content::Canvas.new(stream, document: document)
          end
        end

        # Resolve and concatenate the page's content-stream bytes.
        # /Contents is either a single Stream or an array of Streams.
        def decoded_content
          contents = value[:Contents]
          return "".b if contents.nil?

          streams = contents.is_a?(::Array) ? contents : [contents]
          streams.each_with_object(+"".b) do |ref_or_stream, buf|
            stream = document&.resolve(ref_or_stream)
            next unless stream.is_a?(Pdfrb::Model::Cos::Stream)

            buf << stream.decoded_stream
          end
        end

        # Resolve inheritable /MediaBox by walking up the page tree.
        def media_box
          inheritable(:MediaBox)
        end

        def crop_box
          inheritable(:CropBox) || media_box
        end

        def resources
          inheritable(:Resources)
        end

        def media_box=(box)
          value[:MediaBox] = box
        end

        def bleed_box=(box)
          value[:BleedBox] = box
        end

        def trim_box=(box)
          value[:TrimBox] = box
        end

        def art_box=(box)
          value[:ArtBox] = box
        end

        def crop_box=(box)
          value[:CropBox] = box
        end

        def bleed_box
          value[:BleedBox]
        end

        def trim_box
          value[:TrimBox]
        end

        def art_box
          value[:ArtBox]
        end

        def rotate
          inheritable(:Rotate) || 0
        end

        def parent
          ref = value[:Parent]
          return nil unless ref && document

          document.object(ref)
        end

        def annotations
          self[:Annots]
        end

        def has_annotations?
          !!annotations
        end

        def user_unit
          self[:UserUnit] || 1.0
        end

        def duration
          self[:Dur]
        end

        def transition
          self[:Trans]
        end

        def thumbnail
          self[:Thumb]
        end

        def tab_order
          self[:Tabs]&.to_sym
        end

        def structural_parent
          self[:StructParents]
        end

        def metadata
          self[:Metadata]
        end

        def associated_files
          self[:AF]
        end

        def output_intents
          self[:OutputIntents]
        end

        def group
          self[:Group]
        end

        def has_group?
          !!group
        end

        def rotated?
          rotate != 0
        end

        def landscape?
          mb = media_box
          return false unless mb.is_a?(Array) && mb.size >= 4

          width = mb[2].to_f - mb[0].to_f
          height = mb[3].to_f - mb[1].to_f
          width > height
        end

        def portrait?
          mb = media_box
          return false unless mb.is_a?(Array) && mb.size >= 4

          width = mb[2].to_f - mb[0].to_f
          height = mb[3].to_f - mb[1].to_f
          height > width
        end

        def each_annotation
          return enum_for(:each_annotation) unless block_given?
          return unless annotations && document

          arr = document.resolve(annotations)
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |entry|
            obj = document.resolve(entry)
            yield obj if obj
          end
        end

        private

        def inheritable(key)
          cur = self
          while cur
            val = cur.value[key]
            return val unless val.nil?

            parent_ref = cur.value[:Parent]
            return nil unless parent_ref.is_a?(Pdfrb::Model::Reference)
            return nil unless document

            cur = document.object(parent_ref)
          end
        end
      end
    end
  end
end
