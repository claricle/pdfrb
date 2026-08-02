# frozen_string_literal: true

module Pdfrb
  module Source
    # Reads `%PDF-x.y` header (s7.5.2) and the recommended binary
    # marker comment. Returns the detected version as a String.
    module HeaderReader
      module_function

      def read(io)
        io.seek(0, IO::SEEK_SET)
        # Allow up to 1024 bytes of leading garbage before %PDF per
        # Acrobat tolerance.
        1024.times do
          cur = io.pos
          line = io.gets
          return nil if line.nil?

          if line.start_with?(PdfConstants::HEADER_PREFIX)
            io.seek(cur, IO::SEEK_SET)
            return parse_version(line)
          end
        end
        nil
      end

      def parse_version(line)
        m = line.match(/\A%PDF-(\d+\.\d+)/)
        m ? m[1] : nil
      end
      private_class_method :parse_version
    end
  end
end
