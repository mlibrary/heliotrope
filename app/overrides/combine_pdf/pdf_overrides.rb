CombinePDF::PDF.class_eval do
  prepend(HeliotropeCombinePdfOverrides = Module.new do
    def to_pdf(options = {})
      # reset version if not specified
      @version = 1.5 if @version.to_f == 0.0
      # set info for merged file
      @info[:ModDate] = @info[:CreationDate] = Time.zone.now.strftime "D:%Y%m%d%H%M%S%:::z'00"
      @info[:Subject] = options[:subject] if options[:subject]
      @info[:Producer] = options[:producer] if options[:producer]
      # heliotrope changes, allow setting Information Dictionary "Keywords" value
      @info[:Keywords] = options[:keywords] if options[:keywords]
      # rebuild_catalog
      catalog = rebuild_catalog_and_objects
      # add ID and generation numbers to objects
      renumber_object_ids

      out = []
      xref = []
      indirect_object_count = 1 # the first object is the null object
      # write head (version and binanry-code)
      out << "%PDF-#{@version}\n%\xFF\xFF\xFF\xFF\xFF\x00\x00\x00\x00".force_encoding(Encoding::ASCII_8BIT)

      # collect objects and set xref table locations
      loc = 0
      out.each { |line| loc += line.bytesize + 1 }
      @objects.each do |o|
        indirect_object_count += 1
        xref << loc
        out << object_to_pdf(o)
        loc += out.last.bytesize + 1
      end
      xref_location = loc
      # xref_location = 0
      # out.each { |line| xref_location += line.bytesize + 1}
      out << "xref\n0 #{indirect_object_count}\n0000000000 65535 f \n"
      xref.each { |offset| out << (out.pop + ("%010d 00000 n \n" % offset)) }
      out << out.pop + 'trailer'
      out << "<<\n/Root #{false || "#{catalog[:indirect_reference_id]} #{catalog[:indirect_generation_number]} R"}"
      out << "/Size #{indirect_object_count}"
      out << "/Info #{@info[:indirect_reference_id]} #{@info[:indirect_generation_number]} R"
      out << ">>\nstartxref\n#{xref_location}\n%%EOF"
      # when finished, remove the numbering system and keep only pointers
      remove_old_ids
      # output the pdf stream
      out.join("\n".force_encoding(Encoding::ASCII_8BIT)).force_encoding(Encoding::ASCII_8BIT)
    end
  end)
end
