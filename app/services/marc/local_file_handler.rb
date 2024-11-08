# frozen_string_literal: true

require 'minitar'
require 'zlib'
require 'marc'

module Marc
  class LocalFileHandler
    attr_reader :processing_dir

    def initialize
      @processing_dir = File.join(Settings.scratch_space_path, "marc_processing")
      FileUtils.mkdir_p(@processing_dir) unless Dir.exist? @processing_dir
    end

    def convert_to_individual_marc_files(files)
      marc_files = []
      files.each do |file|
        if file.match?(/\.tar.gz$/)
          # This is a file from Alma. It is .tar.gz compressed and can contain multiple marc records
          untar_dir = ungzip_untar(file)
          next if untar_dir.blank?
          split_marc(untar_dir).each do |marc_file|
            marc_files << marc_file
          end
        else
          # We can accept either Alma .tar.gz files or individual .mrc files.
          # Maybe. Not sure this will work in practice yet.
          marc_files << file
        end
      end

      marc_files
    rescue StandardError => e
      MarcLogger.error("Failed convert_to_individual_marc_files: #{files.join(',')}: #{e}")
      clean_up_processing_dir
      []
    end

    def ungzip_untar(file)
      untar_dir = File.join(@processing_dir, File.basename(file.gsub(/\.tar\.gz$/, "")))
      Minitar.unpack(Zlib::GzipReader.new(File.open(file, 'rb')), untar_dir)
      # The file was unpacked so delete the local copy of the .tar.gz file
      rm(file)
      untar_dir
    rescue StandardError => e
      MarcLogger.error("Failed to ungzip_untar #{file}: #{e}")
      rm(file)
      nil
    end

    def split_marc(untar_dir)
      # This is really only for files we get from Alma
      # Alma makes a single xml file, with 0 or more MARC records, then tars and gzips it and sends it to us
      marc_files = []
      # The file name of the .tar.gz file Alma supplies is the same as the .xml file that is tarred and gzipped
      alma_file = File.join(untar_dir, File.basename(untar_dir)) + ".xml"

      # I guess we're adding namespaces to alma's xml. The ruby-marc gem requires this namespace to be
      # on the collections element or it won't read records and Alma doesn't have it. Great.
      # So we'll just hack it in! Fun and stable! What could go wrong?
      alma_file_handler = File.open(alma_file) # this will raise if the file doesn't exist
      doc = Nokogiri::XML(alma_file_handler)
      # If the xml doc already has the namespace, then this xpath won't work which is fine
      collection = doc.xpath("//collection").first
      collection["xmlns"] = "http://www.loc.gov/MARC21/slim" if collection.present?
      reader = MARC::XMLReader.new(StringIO.new(doc.to_xml), parser: "nokogiri")
      num = 1
      reader.each do |record|
        # We're creating files for each MARC record. Zero pad to 5 places because we don't know anything about the content yet.
        # Later we'll change the names to something better.
        marc_file = File.join(untar_dir, "#{File.basename(untar_dir)}_#{num.to_s.rjust(5, '0')}.xml")
        writer = MARC::XMLWriter.new(marc_file)
        writer.write(record)
        writer.close
        marc_files << marc_file
        num += 1
      end
      marc_files

    rescue StandardError => e
      MarcLogger.error("Failed to split #{alma_file} into multiple MARC records: #{e}")
      e.backtrace.each do |line|
        MarcLogger.error(line)
      end
      []
    end

    def rm(file_or_directory)
      FileUtils.remove_entry_secure(file_or_directory)
    rescue Errno::ENOTEMPTY => e
      # We're getting the .nfs files that are sitting in the processing directory. Annoying.
      #
      # fulcrum@fulcrum-staging-136:~/data/scratch/marc_processing/single_record_from_alma$ rm .nfsdde4bacac1b3f4d000000003
      # rm: cannot remove '.nfsdde4bacac1b3f4d000000003': Device or resource busy
      #
      # I assume the calling job is still holding on to it or something.
      # Eventually it lets them go, but then the directory is still sitting there.
      # It doesn't really matter, it will get cleaned up the next time the job is run.
      # So just log it I guess, don't let it crash everything.
      MarcLogger.info("Failed to delete #{file_or_directory}: #{e}")
    end

    def rename_file_with_noid(validator)
      src = validator.file
      dst = src.gsub(/#{File.basename(src)}$/, "#{validator.noid}.xml")
      FileUtils.move(src, dst)
      dst
    rescue StandardError => e
      MarcLogger.error("Failed to rename '#{src}' to '#{dst}', #{e}")
      nil
    end

    def clean_up_processing_dir
      # Removes everything in the marc_processing directory so do this at the very end
      # We should only ever need to go two directories deep
      Dir[File.join(@processing_dir, "*")].each do |entry|
        if Dir.exist? entry
          Dir[entry].each do |e|
            rm(e)
          end
        else
          rm(entry)
        end
      end
    end
  end
end
