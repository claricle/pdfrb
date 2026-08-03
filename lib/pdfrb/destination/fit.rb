# frozen_string_literal: true

module Pdfrb
  module Destination
    # Destination fit types (ISO 32000-2 §12.3.2.2). Each type specifies
    # how the page should be displayed when navigated to.
    #
    # OCP: new fit type = subclass + register_as.
    class Fit
      class << self
        def registry
          @registry ||= {}
        end

        def register(name, klass)
          registry[name.to_sym] = klass
        end

        def [](name)
          registry[name.to_sym]
        end

        def types
          registry.keys
        end

        def fit_keyword
          raise NotImplementedError
        end

        def register_as(name = fit_keyword)
          Fit.register(name, self)
          self
        end
      end

      attr_reader :page_ref

      def initialize(page_ref)
        @page_ref = page_ref
      end

      # Serialize to the PDF destination array form.
      # @return [Pdfrb::Model::PdfArray]
      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, self.class.fit_keyword])
      end
    end

    # /Fit — fit the entire page in the window.
    class FullPage < Fit
      class << self
        def fit_keyword; :Fit; end
      end
      register_as
    end

    # /FitH top — fit width, top at +top+.
    class FitHorizontal < Fit
      attr_reader :top

      def initialize(page_ref, top: nil)
        super(page_ref)
        @top = top
      end

      class << self
        def fit_keyword; :FitH; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :FitH, @top].compact)
      end
      register_as
    end

    # /FitV left — fit height, left at +left+.
    class FitVertical < Fit
      attr_reader :left

      def initialize(page_ref, left: nil)
        super(page_ref)
        @left = left
      end

      class << self
        def fit_keyword; :FitV; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :FitV, @left].compact)
      end
      register_as
    end

    # /FitR left bottom right top — fit the specified rectangle.
    class FitRectangle < Fit
      attr_reader :left, :bottom, :right, :top

      def initialize(page_ref, left:, bottom:, right:, top:)
        super(page_ref)
        @left = left
        @bottom = bottom
        @right = right
        @top = top
      end

      class << self
        def fit_keyword; :FitR; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :FitR, @left, @bottom, @right, @top])
      end
      register_as
    end

    # /XYZ left top zoom — explicit position and zoom.
    class XYZ < Fit
      attr_reader :left, :top, :zoom

      def initialize(page_ref, left: nil, top: nil, zoom: nil)
        super(page_ref)
        @left = left
        @top = top
        @zoom = zoom
      end

      class << self
        def fit_keyword; :XYZ; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :XYZ, @left, @top, @zoom].compact)
      end
      register_as
    end

    # /FitB — fit the bounding box of the page contents.
    class FitBoundingBox < Fit
      class << self
        def fit_keyword; :FitB; end
      end
      register_as
    end

    # /FitBH top — fit bounding box width, top at +top+.
    class FitBoundingBoxHorizontal < Fit
      attr_reader :top

      def initialize(page_ref, top: nil)
        super(page_ref)
        @top = top
      end

      class << self
        def fit_keyword; :FitBH; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :FitBH, @top].compact)
      end
      register_as
    end

    # /FitBV left — fit bounding box height, left at +left+.
    class FitBoundingBoxVertical < Fit
      attr_reader :left

      def initialize(page_ref, left: nil)
        super(page_ref)
        @left = left
      end

      class << self
        def fit_keyword; :FitBV; end
      end

      def to_pdf
        Pdfrb::Model::PdfArray.new([@page_ref, :FitBV, @left].compact)
      end
      register_as
    end
  end
end
