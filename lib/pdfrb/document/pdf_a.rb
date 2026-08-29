# frozen_string_literal: true

module Pdfrb
  class Document
    # PDF/A production helper (ISO 19005-2). Installs the three
    # things a conforming file must carry that a generic document
    # does not:
    #
    #   * a GTS_PDFA1 OutputIntent with an embedded sRGB ICC
    #     profile (DeviceGray/RGB rendering legitimacy),
    #   * an XMP metadata stream carrying the pdfaid identification
    #     (part + conformance) on the Catalog,
    #   * a document Title so the XMP synchronises on write.
    #
    # Fonts must be EMBEDDED separately (fonts.add with a file path);
    # the standard-14 names alone do not satisfy 6.2.11.4.1.
    module PdfA
      SRGB_IDENTIFIER = "sRGB IEC61966-2.1"
      SRGB_REGISTRY = "http://www.color.org"

      # @param part [Integer] 1, 2, 3, or 4.
      # @param conformance [String] "B" (basic), "A", or "U".
      def enable_pdf_a!(part: 2, conformance: "B")
        self.version = part == 4 ? "2.0" : "1.7"

        srgb_output_intent
        metadata[:Title] ||= "Untitled"
        packet = xmp || Pdfrb::XMP::Packet.new
        packet.pdfa_id = { part: part, conformance: conformance }
        @xmp = packet
        @pdfa_part = part
        @pdfa_conformance = conformance
        self
      end

      def pdfa_part; @pdfa_part; end
      def pdfa_conformance; @pdfa_conformance; end

      private

      def srgb_output_intent
        catalog = self.catalog
        intents = catalog.value[:OutputIntents]
        return if intents

        bytes = Pdfrb::Color::DefaultProfile.srgb_bytes
        icc = add({ N: 3, Length: bytes.bytesize },
                  type: Pdfrb::Model::Cos::Stream)
        icc.stream = bytes
        output_intents.add(
          icc.ref,
          identifier: SRGB_IDENTIFIER,
          condition: "sRGB IEC61966-2.1",
          registry: SRGB_REGISTRY,
          subtype: :GTS_PDFA1
        )
      end
    end
  end
end
