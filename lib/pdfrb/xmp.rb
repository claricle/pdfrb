# frozen_string_literal: true

module Pdfrb
  module XMP
    autoload :Packet, "pdfrb/xmp/packet"
    autoload :Schemas, "pdfrb/xmp/schemas"
  end
end

Pdfrb::Document.prepend(Module.new do
  def write(path = nil, io: nil)
    sync_xmp_metadata! unless self.io
    super
  end

  private

  def sync_xmp_metadata!
    info = trailer&.[](:Info)
    return unless info

    info_obj = object(info)
    return unless info_obj

    title = info_obj.value[:Title]
    return unless title

    packet = begin
      xmp
    rescue StandardError
      nil
    end
    return unless packet

    xmp_data = packet.to_xmp
    stream = add(
      { Type: :Metadata, Subtype: :XML, Length: xmp_data.bytesize },
      type: Pdfrb::Model::Cos::Stream
    )
    stream.stream = xmp_data
    catalog.value[:Metadata] =
      Pdfrb::Model::Reference.new(stream.oid, stream.gen)
  end
end)
