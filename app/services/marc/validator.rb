# frozen_string_literal: true

module Marc
  class Validator
    attr_reader :file, :reader, :noid, :group_key, :error

    def initialize(file)
      @file = file
      @reader = read_marc
    end

    # Take in a file containing one or more marc records
    # If any part of any record is invalid, the whole thing is invalid
    # I think generally we'll use this Validator on single records but it
    # leaves open the possibilty of also validating concatenated marc too.
    def valid?
      rvalue = true
      @reader.each do |record|
        @noid = nil
        @group_key = nil

        # The order of these validations matters

        rvalue = ruby_marc_valid?(record)
        break unless rvalue

        rvalue = valid_024?(record)
        break unless rvalue

        rvalue = exists_in_fulcrum?(record)
        break unless rvalue

        # At this point we have a @group_key and @noid for the record

        rvalue = valid_001?(record)
        break unless rvalue

        rvalue = valid_003?(record)
        break unless rvalue

        rvalue = valid_020?(record)
        break unless rvalue

        rvalue = valid_856?(record)
      end

      rvalue
    rescue StandardError => e
      log_message("ruby-marc can't open record! #{e}")
      MarcLogger.error(e.backtrace.join("\n"))
      false
    end

    # This is from the ruby-marc gem. I don't think this means too much really in this context.
    # Maybe in the future we can explore this more.
    def ruby_marc_valid?(record)
      unless record.valid?
        log_message("is not valid according to ruby-marc")
        MarcLogger.error(record.errors.join("\n"))
        return false
      end

      true
    end

    # See HELIO-4760
    # We're using Marc::DirectoryMapper.press_group_key to match the book's press to it's group_key.
    # This means monographs only need as valid 024$a field and do not need Components/Products/etc
    def exists_in_fulcrum?(record)
      # We've already determined that something exists in the 024$a field.
      # We need to match that with a monograph in fulcrum
      # When we do that, we also will get the group_key
      purl = record["024"]["a"]
      doc = ActiveFedora::SolrService.query("+doi_ssim:#{purl}", fl: ['id', 'press_tesim'], rows: 1)&.first
      if doc.present?
        @noid = doc['id']
        @group_key = Marc::DirectoryMapper.press_group_key[doc['press_tesim'].first]
      else
        row = HandleDeposit.where(handle: purl).first
        if row.present?
          url = row.url_value
          m = url.match(/.*\/(.*)$/)
          @noid = m[1] if m[1].present?
          doc = ActiveFedora::SolrService.query("{!terms f=id}#{@noid}", fl: ['press_tesim'], rows: 1)&.first
          if doc.present?
            @group_key = Marc::DirectoryMapper.press_group_key[doc['press_tesim'].first]
          end
        end
      end

      if @noid.blank?
        log_message("does not have a DOI or Handle that is in fulcrum, 024$a value is '#{purl}'")
        return false
      end

      # I guess records can still "exist_in_fulcrum?" if they don't have a group_key
      # Handle that "error" in what ever calls the Validator since it's not exactly an "error",
      # it just means we need to add the group_key to the Marc::DirectoryMapper or something.

      true
    end

    # Some documentation on what we expect in MARC fields. This is for BAR and HEB but a lot of it will apply
    # to Michigan and the other presses that UMich provides marc records for (amherst, lever, etc)
    # https://mpub.atlassian.net/wiki/spaces/FPS/pages/82151257/Requirements+for+MARC+Records+for+ACLS+Humanities+Ebook
    # https://mpub.atlassian.net/wiki/spaces/FPS/pages/80086528/MARC+Records+for+British+Archeological+Reports


    # BAR
    #   001 is required and must not include the OCLC Control Number. The organization code 'UkOxBAR' may be included.
    # HEB (and everything else?)
    #   001 is required and must not include the OCLC Control Number. The organization code 'MiU' or 'MIU' may be included.
    #
    # OCLC numbers look like this (OCoLC)1395949003 or maybe this (OCoLC)ocn123539484
    # In OCLC itself they are like 123539484 which we can't do anything about. We'll just use the "OCoLC" bit I guess
    def valid_001?(record)
      if record["001"].blank?
        log_message("has no 001 field")
        return false
      end

      if record["001"].value.match?("OCoLC")
        log_message("has 'OCoLC' in the 001 field")
        return false
      end

      true
    end

    # BAR
    #   003: Use organization code 'UkOxBAR'.
    # HEB (and probably everything else?)
    #   003: Use organization code 'MiU'.
    def valid_003?(record)
      if record["003"].blank?
        log_message("has no 003 field")
        return false
      end

      if @group_key == "bar"
        unless record["003"].value == "UkOxBAR"
          log_message("003 value is not 'UkOxBAR' it is '#{record["003"].value}'")
          return false
        end
      else
        unless record["003"].value == "MiU"
          log_message("003 value is not 'MiU' it is '#{record["003"].value}'")
          return false
        end
      end

      true
    end

    # 020: eISBNs should be in subfield $a; print ISBNs must be in subfield $z.
    # For the formats in subfield $q, we recommend the following controlled vocabulary:
    #     ebook
    #     paper
    #     hardcover
    def valid_020?(record)
      # I think I'm not going to validate any kind of controlled vocabulary, we'll just make sure it's got
      # some kind of ISBN somewhere
      if record["020"].blank? || (record["020"]["a"].blank? && record["020"]["z"].blank?)
        log_message("020$a and 020$z have no ISBN values")
        return false
      end

      true
    end

    # We're depending on this field to match the marc record with the fulcrum monograph
    # 024: Include this field with the DOI in subfield $a and the designator 'doi' in subfield $2. The value of the First Indicator must be '7'.
    #   The DOI is the value in 856$u minus 'https://doi.org/'.
    # 024: Include this field with the Handle in subfield $a and the designator 'hdl' in subfield $2. The value of the First Indicator must be '7'.
    #   The Handle is the value in 856$u minus 'https://hdl.handle.net/'.
    def valid_024?(record)
      if record["024"].blank?
        log_message("has no 024 field")
        return false
      end

      if record["024"]["a"].blank?
        log_message("has no 024 $a field")
        return false
      end

      true
    end

    # BAR
    #   856 $u must contain the DOI URL
    # HEB
    #   856 $u must contain the full Handle URL as it appears under 'Citable Link' on the book's landing page on Fulcrum. Optionally, $z may include 'Electronic access restricted; authentication may be required:'
    #
    # Currently everything has a DOI except for HEB which uses handles
    # If we made it this far in the validations we know it's got one or the other and that the book exists in Fulcrum
    # So here we just want to make sure 856 is present.
    # It would be very unusual if it wasn't.
    # But should we compare 024$a and 856$u? I'm not going to for now. We'll see.
    def valid_856?(record)
      if record["856"].blank? || record["856"]["u"].blank?
        log_message("has no 856$u field")
        return false
      end

      true
    end


    def log_message(message)
      group_and_noid = if @group_key.present?
                         "#{@group_key} #{@noid} "
                       else
                         nil
                       end
      full_message = "ERROR\t#{group_and_noid || ''}#{File.basename(@file)} #{message}"
      @error = full_message
      MarcLogger.error(full_message)
    end

    def read_marc
      if xml?
        MARC::XMLReader.new(@file, parser: "magic")
      else
        MARC::Reader.new(@file)
      end
    rescue
      log_message("ruby-marc could not read file")
    end

    def xml?
      # TODO: make this not dumb
      return true if @file.match?(/\.xml$/)
      false
    end
  end
end
