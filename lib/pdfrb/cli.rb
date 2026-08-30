# frozen_string_literal: true

require "thor"
require "pdfrb"

module Pdfrb
  # `pdfrb` executable. Thor-based CLI mirroring `pdftk`/`pdfinfo`
  # ergonomics. Each subcommand wraps a +Task::*+ module or reads
  # directly off the +Document+ facade.
  class CLI < Thor
    package_name "pdfrb"

    desc "version", "Print the pdfrb version"
    def version
      puts "pdfrb #{Pdfrb::VERSION}"
    end

    desc "info INPUT", "Print document metadata, page count, encryption status"
    def info(input)
      doc = open_doc(input)
      puts "File: #{input}"
      puts "PDF version: #{doc.version}"
      puts "Pages: #{doc.pages.count}"
      puts "Title: #{doc.metadata.title || '-'}"
      puts "Author: #{doc.metadata.author || '-'}"
      puts "Subject: #{doc.metadata.subject || '-'}"
      puts "Producer: #{doc.metadata.producer || '-'}"
      puts "Encrypted: #{encrypted?(doc)}"
    end

    desc "merge OUTPUT INPUT...", "Merge multiple PDFs into OUTPUT (in order)"
    def merge(output, *inputs)
      raise ArgumentError, "merge needs at least one INPUT" if inputs.empty?

      target = Pdfrb::Document.new
      inputs.each { |i| Pdfrb::Task::Merge.call(target, open_doc(i)) }
      target.write(output)
      puts "Wrote #{output} (#{target.pages.count} pages)"
    end

    desc "extract-text INPUT [OUTPUT]", "Extract text from each page"
    def extract_text(input, output = nil)
      doc = open_doc(input)
      texts = Pdfrb::Task::ExtractText.call(doc)
      if output
        File.write(output, texts.join("\n\n--- page break ---\n\n"))
        puts "Wrote #{output}"
      else
        texts.each_with_index { |t, i| puts "--- page #{i + 1} ---"; puts t }
      end
    end

    desc "images INPUT", "List image XObjects in the document"
    def images(input)
      doc = open_doc(input)
      Pdfrb::Task::ExtractImages.call(doc) do |info|
        puts "page #{info.page_index + 1} /#{info.name} " \
             "#{info.width}x#{info.height} filter=#{info.filter.inspect}"
      end
    end

    desc "optimize INPUT OUTPUT", "Optimize: dedup objects, pack into ObjStm, rewrite xref stream"
    def optimize(input, output)
      doc = open_doc(input)
      Pdfrb::Task::Optimize.call(doc)
      doc.write(output)
      puts "Wrote #{output}"
    end

    desc "diff LEFT RIGHT", "Compare two PDFs semantically"
    def diff(left, right)
      report = Pdfrb::Compare.compare(
        File.binread(left),
        File.binread(right)
      )
      puts report.summary
      unless report.equivalent?
        puts
        report.per_page_text_diffs.first(5).each do |d|
          puts "  Page #{d[:page] + 1}: #{(d[:similarity] * 100).round(1)}% similar"
        end
        unless report.font_diff[:added].empty? && report.font_diff[:removed].empty?
          puts "  Fonts added: #{report.font_diff[:added].join(', ')}" unless report.font_diff[:added].empty?
          puts "  Fonts removed: #{report.font_diff[:removed].join(', ')}" unless report.font_diff[:removed].empty?
        end
        puts "  Page count delta: #{report.page_count_delta}" unless report.page_count_delta.zero?
        exit 1
      end
    end

    desc "encrypt INPUT OUTPUT --password PASSWORD", "Encrypt a PDF with RC4 or AES"
    method_option :password, type: :string, required: true
    method_option :owner_password, type: :string, default: nil
    method_option :bits, type: :numeric, default: 128, banner: "40|128|256"
    method_option :permissions, type: :string, default: "",
                                banner: "print,copy,modify,annotate,fill,extract,assemble,print-hq"
    def encrypt(input, output)
      doc = open_doc(input)
      bits = options[:bits]
      password = options[:password]
      owner_pw = options[:owner_password] || password

      perms = parse_permissions(options[:permissions])

      # Build the /Encrypt dictionary.
      case bits
      when 256
        build_aes256_encrypt(doc, password, owner_pw, perms)
      when 128
        build_encrypt(doc, password, owner_pw, perms, v: 4, r: 4, length: 128)
      when 40
        build_encrypt(doc, password, owner_pw, perms, v: 2, r: 3, length: 40)
      else
        raise "unsupported key length: #{bits} (use 40, 128, or 256)"
      end

      doc.write(output)
      puts "Encrypted #{output} (#{bits}-bit)"
    end

    desc "decrypt INPUT OUTPUT --password PASSWORD", "Decrypt a PDF (remove /Encrypt)"
    method_option :password, type: :string, default: ""
    def decrypt(input, output)
      doc = open_doc(input)

      # Strip /Encrypt from trailer and clear handler config so the
      # Writer doesn't re-encrypt on output.
      trailer = doc.trailer
      if trailer && trailer[:Encrypt]
        trailer.value.delete(:Encrypt)
        doc.config.delete("encryption.handler")
        doc.config.delete("encryption.password")
        puts "Stripped encryption"
      end

      doc.write(output)
      puts "Decrypted → #{output}"
    end

    desc "images-add INPUT IMAGE OUTPUT", "Add an image to a new page"
    def images_add(input, image, output)
      doc = open_doc(input)
      name = doc.images.add(image)
      doc.pages.add # just adds a blank page for now
      doc.write(output)
      puts "Added image as /#{name} and wrote #{output}"
    end

    desc "form INPUT", "List AcroForm fields"
    def form(input)
      doc = open_doc(input)
      acro = doc.catalog[:AcroForm]
      if acro.nil?
        puts "No AcroForm in this document."
        return
      end
      fields = acro[:Fields]
      return unless fields

      fields.each do |ref|
        field = doc.resolve(ref)
        next unless field

        name = field[:T] || "(unnamed)"
        type = field[:FT] || "?"
        value = field[:V] || "-"
        puts "/#{name}  type=#{type}  value=#{value}"
      end
    end

    desc "split INPUT OUTPUT_PATTERN [FROM [TO]]", "Split a PDF into individual pages"
    def split(input, output_pattern, from = nil, to = nil)
      doc = open_doc(input)
      total = doc.pages.count
      from_idx = from ? from.to_i : 1
      to_idx = to ? to.to_i : total
      (from_idx..to_idx).each do |i|
        target = Pdfrb::Document.new
        Pdfrb::Importer.new(target).import(doc.pages[i - 1].value, doc)
        out_path = format(output_pattern, i)
        target.write(out_path)
      end
      puts "Split #{input} into #{to_idx - from_idx + 1} files"
    end

    desc "watermark INPUT OUTPUT --text TEXT", "Stamp text on every page"
    method_option :text, type: :string, required: true
    method_option :font, type: :string, default: "Helvetica"
    method_option :size, type: :numeric, default: 50
    method_option :color, type: :string, default: "0.5,0.5,0.5"
    method_option :opacity, type: :numeric, default: 0.3
    method_option :angle, type: :numeric, default: 45
    def watermark(input, output)
      doc = open_doc(input)
      color = options[:color].split(",").map(&:to_f)
      doc.pages.each do |page|
        canvas = page.canvas
        doc.graphics_state.register_transparency(page, opacity: options[:opacity])
        canvas.save_graphics_state
        canvas.opacity = options[:opacity]
        canvas.fill_color(color)
        canvas.text(options[:text], at: [100, 400],
                                    font: options[:font].to_sym,
                                    size: options[:size])
        canvas.restore_graphics_state
      end
      doc.write(output)
      puts "Watermarked #{doc.pages.count} pages → #{output}"
    end

    desc "modify INPUT OUTPUT", "Apply modifications to a PDF"
    method_option :delete, type: :string, banner: "PAGE_RANGE e.g. 1-3,5"
    method_option :rotate, type: :numeric, banner: "ANGLE 0/90/180/270"
    def modify(input, output)
      doc = open_doc(input)
      apply_delete(doc, options[:delete]) if options[:delete]
      apply_rotate(doc, options[:rotate]) if options[:rotate]
      doc.write(output)
      puts "Modified → #{output}"
    end

    desc "inspect INPUT", "Walk the PDF structure"
    method_option :object, type: :numeric, banner: "OID to dump"
    def inspect(input)
      doc = open_doc(input)
      if options[:object]
        ref = Pdfrb::Model::Reference.new(options[:object], 0)
        obj = doc.object(ref)
        puts obj&.value
        return
      end

      catalog = doc.catalog
      puts "Catalog: /Type=#{catalog[:Type]}"
      puts "  Pages: #{doc.pages.count}"
      puts "  Title: #{doc.metadata.title || '-'}"
      af = catalog[:AcroForm]
      puts "  AcroForm: #{af ? 'present' : 'absent'}"
      outlines = catalog[:Outlines]
      puts "  Outlines: #{outlines ? 'present' : 'absent'}"
    end

    desc "files INPUT", "List embedded files in the document"
    def files(input)
      doc = open_doc(input)
      if doc.files.empty?
        puts "No embedded files."
        return
      end
      doc.files.each do |name, spec|
        size = spec[:EF] ? "embedded" : "external"
        puts "#{name}  (#{size})"
      end
    end

    desc "files-add INPUT OUTPUT FILE", "Embed a file into the document"
    method_option :relationship, type: :string, default: nil
    def files_add(input, output, file)
      doc = open_doc(input)
      doc.files.add(file, name: File.basename(file),
                          relationship: options[:relationship]&.to_sym)
      doc.write(output)
      puts "Embedded #{file} → #{output}"
    end

    desc "batch INPUT OUTPUT COMMAND1 ARGS... -- COMMAND2 ARGS...",
         "Run multiple operations on a single document"
    def batch(input, output, *args)
      doc = open_doc(input)
      commands = args.split("--").reject(&:empty?)
      commands.each do |cmd_args|
        cmd, *cmd_args = cmd_args
        apply_batch_command(doc, cmd, cmd_args)
      end
      doc.write(output)
      puts "Batch processed → #{output}"
    end

    PERMISSION_BITS = {
      "print" => 4,
      "modify" => 8,
      "copy" => 16,
      "annotate" => 32,
      "fill" => 256,
      "extract" => 512,
      "assemble" => 1024,
      "print-hq" => 2048,
    }.freeze

    private

    def parse_permissions(spec)
      return -1 if spec.empty? || spec == "all"

      granted = PERMISSION_BITS.values.sum
      spec.split(",").map(&:strip).each do |perm|
        bit = PERMISSION_BITS[perm]
        granted &= ~bit if bit
      end
      granted
    end

    def build_encrypt(doc, user_pw, owner_pw, perms, v:, r:, length:)
      require "digest/md5"

      id0 = Digest::MD5.hexdigest(Time.now.to_s + rand.to_s)[0, 16]
      doc.trailer[:ID] = [id0.b, id0.b]

      # Compute /O entry (owner password hash).
      o_entry = compute_o_entry(user_pw, owner_pw, r, length)

      # Derive encryption key from user password (Algorithm 2).
      key = Pdfrb::Encryption::PasswordVerification.derive_key_rc4(
        password: user_pw, o_entry: o_entry.b, p_flags: perms,
        id0: id0.b, revision: r, key_length_bits: length,
        encrypt_metadata: true
      )

      # Build /U entry (Algorithm 4/5).
      u_entry = if r == 2
                  Pdfrb::Encryption::PasswordVerification.build_u_r2(key)
                else
                  Pdfrb::Encryption::PasswordVerification.build_u_r3plus(
                    file_key: key, id0: id0.b, revision: r
                  )
                end

      encrypt_dict = doc.add(
        { Filter: :Standard, V: v, R: r, Length: length, P: perms,
          O: o_entry, U: u_entry },
        type: Pdfrb::Model::Cos::Dictionary
      )
      doc.trailer[:Encrypt] = encrypt_dict.ref

      # Set up the handler so Writer can encrypt per-object.
      handler = Pdfrb::Encryption::StandardSecurityHandler.new(
        {
          Encrypt: { V: v, R: r, Length: length, P: perms,
                     O: o_entry, U: u_entry },
          ID: [id0.b, id0.b],
        }
      )
      unless handler.verify_user_password?(user_pw)
        raise Pdfrb::EncryptionError, "failed to derive encryption key"
      end

      doc.config["encryption.handler"] = handler
      doc.config["encryption.password"] = user_pw
    end

    def build_aes256_encrypt(doc, user_pw, owner_pw, perms)
      require "digest/sha2"
      require "securerandom"

      val_salt = SecureRandom.random_bytes(8)
      key_salt = SecureRandom.random_bytes(8)
      u_hash = Digest::SHA256.digest(user_pw + val_salt)
      u_entry = u_hash + val_salt + key_salt

      o_val_salt = SecureRandom.random_bytes(8)
      o_key_salt = SecureRandom.random_bytes(8)
      o_hash = Digest::SHA256.digest(owner_pw + o_val_salt + u_hash)
      o_entry = o_hash + o_val_salt + o_key_salt

      id0 = Digest::MD5.hexdigest(Time.now.to_s + rand.to_s)[0, 16]
      doc.trailer[:ID] = [id0.b, id0.b]

      encrypt_dict = doc.add(
        { Filter: :Standard, V: 5, R: 6, Length: 256, P: perms,
          O: o_entry, U: u_entry, OE: "".b, UE: "".b },
        type: Pdfrb::Model::Cos::Dictionary
      )
      doc.trailer[:Encrypt] = encrypt_dict.ref
      doc.config["encryption.password"] = user_pw
    end

    def compute_o_entry(user_pw, owner_pw, revision, length_bits)
      Pdfrb::Encryption::PasswordVerification.pad_password(owner_pw)
      require "digest/md5"
      padded = Pdfrb::Encryption::PasswordVerification.pad_password(owner_pw)
      hash = Digest::MD5.digest(padded)

      if revision >= 3
        50.times { hash = Digest::MD5.digest(hash[0, length_bits / 8]) }
      end

      rc4 = Pdfrb::Encryption::RC4.new(hash[0, length_bits / 8])
      user_padded = Pdfrb::Encryption::PasswordVerification.pad_password(user_pw)
      result = rc4.process(user_padded)

      if revision >= 3
        19.times do |i|
          key = hash[0, length_bits / 8].bytes.map { |b| (b ^ i).chr }.join
          result = Pdfrb::Encryption::RC4.new(key).process(result)
        end
      end

      result + ("\x00".b * [0, 32 - result.bytesize].max)
    end

    def apply_delete(doc, range_spec)
      ranges = range_spec.split(",").map { |r| parse_range(r, doc.pages.count) }
      oids_to_delete = []
      ranges.each do |(from, to)|
        (from..to).each { |i| oids_to_delete << doc.pages[i - 1].oid }
      end
      oids_to_delete.uniq.each { |oid| doc.pages.delete_at(oid) }
    end

    def apply_rotate(doc, angle)
      doc.pages.each { |page| page.value[:Rotate] = angle }
    end

    def parse_range(spec, _total)
      if spec.include?("-")
        from, to = spec.split("-").map(&:to_i)
        [from, to]
      else
        n = spec.to_i
        [n, n]
      end
    end

    def apply_batch_command(doc, cmd, args)
      case cmd
      when "rotate" then apply_rotate(doc, args.first.to_i)
      when "delete" then apply_delete(doc, args.first)
      else warn "unknown batch command: #{cmd}"
      end
    end

    def open_doc(path)
      raise "no such file: #{path}" unless File.exist?(path)

      Pdfrb::Document.open(path)
    rescue Pdfrb::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    def encrypted?(doc)
      trailer = doc.trailer
      trailer ? !trailer[:Encrypt].nil? : false
    end
  end
end
