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
                value[:Contents] = Pdfrb::Model::Reference.new(new_stream.oid, 0)
                new_stream
              else
                ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
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
            stream = ref_or_stream.is_a?(Pdfrb::Model::Reference) ?
                       document&.object(ref_or_stream) : ref_or_stream
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
          self.value[:MediaBox] = box
        end

        def bleed_box=(box)
          self.value[:BleedBox] = box
        end

        def trim_box=(box)
          self.value[:TrimBox] = box
        end

        def art_box=(box)
          self.value[:ArtBox] = box
        end

        def crop_box=(box)
          self.value[:CropBox] = box
        end

        def bleed_box
          self.value[:BleedBox]
        end

        def trim_box
          self.value[:TrimBox]
        end

        def art_box
          self.value[:ArtBox]
        end
        def rotate
          inheritable(:Rotate) || 0
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
