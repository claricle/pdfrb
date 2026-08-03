# frozen_string_literal: true

begin; require "lutaml/model"; rescue LoadError; end

module Pdfrb
  module XMP
    # XMP packet wrapper. An XMP packet is an XML document wrapped in
    # processing instructions: <?xpacket begin?> ... <?xpacket end?>.
    #
    # The packet contains an RDF document with one Description element
    # per schema. This class assembles the schemas into a single RDF
    # Description and wraps it in the packet PI.
    class Packet
      XMP_BEGIN = "<?xpacket begin=\"﻿\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n"
      XMP_END = "<?xpacket end=\"w\"?>\n"

      attr_reader :dc, :pdf, :xmp, :rights

      def initialize
        @dc = Schemas::DublinCore.new
        @pdf = Schemas::PDF.new
        @xmp = Schemas::XMPBasic.new
        @rights = Schemas::XMPRights.new
      end

      def title=(value); @dc.title = Array(value); end
      def title; @dc.title.first; end
      def creator=(value); @dc.creator = Array(value); end
      def creator; @dc.creator.first; end
      def description=(value); @dc.description = Array(value); end
      def description; @dc.description.first; end
      def subject=(value); @dc.subject = Array(value); end
      def subject; @dc.subject; end

      def keywords=(value); @pdf.keywords = value; end
      def keywords; @pdf.keywords; end
      def producer=(value); @pdf.producer = value; end
      def producer; @pdf.producer; end

      def creator_tool=(value); @xmp.creator_tool = value; end
      def creator_tool; @xmp.creator_tool; end

      def to_xmp
        XMP_BEGIN + rdf_body + XMP_END
      end

      private

      def rdf_body
        lines = [
          '<x:xmpmeta xmlns:x="adobe:ns:meta/">',
          '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">',
          '<rdf:Description rdf:about=""',
          '    xmlns:dc="http://purl.org/dc/elements/1.1/"',
          '    xmlns:pdf="http://ns.adobe.com/pdf/1.3/"',
          '    xmlns:xmp="http://ns.adobe.com/xap/1.0/">',
        ]
        lines += schema_lines
        lines << "</rdf:Description>"
        lines << "</rdf:RDF>"
        lines << "</x:xmpmeta>"
        "#{lines.join("\n")}\n"
      end

      def schema_lines
        parts = []
        parts += dc_lines if has_dc?
        parts += pdf_lines if has_pdf?
        parts += xmp_lines if has_xmp?
        parts
      end

      def has_dc?
        (@dc.title && !@dc.title.empty?) ||
          (@dc.creator && !@dc.creator.empty?) ||
          (@dc.description && !@dc.description.empty?) ||
          (@dc.subject && !@dc.subject.empty?)
      end

      def has_pdf?
        @pdf.keywords || @pdf.producer || @pdf.trapped
      end

      def has_xmp?
        @xmp.creator_tool || @xmp.create_date || @xmp.modify_date
      end

      def dc_lines
        lines = (@dc.title || []).map { |t| "  <dc:title><rdf:Alt><rdf:li xml:lang=\"x-default\">#{escape(t)}</rdf:li></rdf:Alt></dc:title>" }
        (@dc.creator || []).each { |c| lines << "  <dc:creator><rdf:Seq><rdf:li>#{escape(c)}</rdf:li></rdf:Seq></dc:creator>" }
        (@dc.description || []).each { |d| lines << "  <dc:description><rdf:Alt><rdf:li xml:lang=\"x-default\">#{escape(d)}</rdf:li></rdf:Alt></dc:description>" }
        (@dc.subject || []).each { |s| lines << "  <dc:subject><rdf:Bag><rdf:li>#{escape(s)}</rdf:li></rdf:Bag></dc:subject>" }
        lines
      end

      def pdf_lines
        lines = []
        lines << "  <pdf:Keywords>#{escape(@pdf.keywords)}</pdf:Keywords>" if @pdf.keywords
        lines << "  <pdf:Producer>#{escape(@pdf.producer)}</pdf:Producer>" if @pdf.producer
        lines
      end

      def xmp_lines
        lines = []
        lines << "  <xmp:CreatorTool>#{escape(@xmp.creator_tool)}</xmp:CreatorTool>" if @xmp.creator_tool
        lines << "  <xmp:CreateDate>#{@xmp.create_date}</xmp:CreateDate>" if @xmp.create_date
        lines << "  <xmp:ModifyDate>#{@xmp.modify_date}</xmp:ModifyDate>" if @xmp.modify_date
        lines
      end

      def escape(str)
        str.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
      end
    end
  end
end
