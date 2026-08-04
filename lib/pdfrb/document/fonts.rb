      def font_name_for(name_or_io)
        case name_or_io
        when Symbol
          name_or_io.to_s
        when String
          if File.file?(name_or_io)
            @pending_io_data = File.binread(name_or_io)
            @pending_subtype = true_type_subtype(@pending_io_data)
            "FileFont-#{File.basename(name_or_io, ".*")}"
          else
            name_or_io.to_s
          end
        when IO, StringIO
          @pending_io_data = name_or_io.read
          unless valid_font_data?(@pending_io_data)
            Pdfrb.logger&.warn("Font data does not look like a valid TTF/OTF")
          end
          @pending_subtype = true_type_subtype(@pending_io_data)
          "EmbeddedFont-#{@pending_io_data.bytesize}"
        else
          raise ArgumentError, "font name must be a String, Symbol, or IO"
        end
      end

      def true_type_subtype(data)
        magic = data&.byteslice(0, 4)
        return :TrueType if ["\x00\x01\x00\x00".b, "true".b, "OTTO".b].include?(magic)
        nil
      end