# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# "Items" refers to objects, a.k.a. Monographs and FileSets
desc 'Upload Items Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_items, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_items[output_directory]"

    # starting with COUNTER 5.1 we need to use a controlled vocabulary for Data Type
    # TODO: Decide on whether we want to allow the optional use of the actual COUNTER data type terms in our resource type field at some stage?
    # Though we'd need to replace the underscore with a space in the Format facet.
    # Another thing we might want to do is to fall back on are the FeaturedRepresentative kind values associated with the FileSet,....
    # as well as the mime type to reduce the number of Unspecified values emitted from this.
    RESOURCE_TYPE_TO_COUNTER_DATA_TYPE_MAP = {
      '3d model' => 'Interactive_Resource',
      'animated gif' => 'Multimedia',
      'appendix' => 'Book_Segment',
      'audio' => 'Sound',
      'chapter' => 'Book_Segment',
      'chart' => 'Other',
      'code' => 'Software',
      'database' => 'Dataset',
      'dataset' => 'Dataset',
      'documentary' => 'Audiovisual',
      'external resource' => 'Dataset',
      'figure' => 'Image',
      'image' => 'Image',
      'interactive application' => 'Interactive_Resource',
      'interactive map' => 'Interactive_Resource',
      'map' => 'Image',
      'musical example' => 'Other',
      'pdf' => 'Unspecified',
      'table' => 'Dataset',
      'text' => 'Unspecified',
      'video' => 'Audiovisual',
      'website' => 'Other',
      nil => 'Unspecified'
    }.freeze

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # For now let's assume these will be tidied up manually, or by a separate cron
    output_file = File.join(args.output_directory, "items-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")

    field_list = ['id', 'has_model_ssim', 'monograph_id_ssim', 'title_tesim', 'creator_ss', 'date_created_tesim',
                  'doi_ssim', 'identifier_tesim', 'resource_type_tesim', 'isbn_tesim', 'hidden_representative_bsi']
    # want to break the Monographs out separately and run through them first to reuse them for "enhancing" FileSet rows
    monograph_docs = ActiveFedora::SolrService.query('+(has_model_ssim:Monograph)',
                                                     fl: field_list, rows: 100_000)
    file_set_docs = ActiveFedora::SolrService.query('+has_model_ssim:FileSet',
                                                     fl: field_list, rows: 100_000)

    CSV.open(output_file, "w", col_sep: "\t") do |tsv|
      # we'll leave the heading here as resource_type as that's what SiQ expects, even though we're converting to COUNTER 5.1 "data types" now
      tsv << %w[id parent_id title creator date_created doi identifier resource_type counter_data_type isbn primary_isbn]

      # write all actual ActiveFedora objects, pulled from Solr. Loop Monographs first, then FileSets (see comment above),..
      # then write all EbookTableOfContentsCache objects, pulled from MySQL, as our "Book Segments"
      monograph_docs.each do |monograph_doc|
        isbns = monograph_doc['isbn_tesim']&.map(&:strip)&.reject(&:blank?)

        # stick these isbn fields in the doc/hash to reuse later on associated FileSets and EbookTableOfContentsCache rows (along with date_created)
        monograph_doc['all_isbns_for_siq'] = isbns.join('; ') if isbns.present?
        monograph_doc['primary_isbn_for_siq'] = if isbns.present?
                                                  # these methods return "" if they can't find anything (which is truthy)
                                                  online_isbn(isbns).presence || print_isbn(isbns).presence
                                                else
                                                  nil
                                                end
        # the copied-from-BuildKbartJob methods above return "" if they have no recognized format etc, but we'll just...
        # grab any isbn that may be left over, sans the format bit, for SiQ if we end up here
        if monograph_doc['primary_isbn_for_siq'].blank? && isbns.present?
          formatless_isbns = isbns.map { |val| val&.strip&.sub(/\s*\(.+\)$/, '')&.strip }
          monograph_doc['primary_isbn_for_siq'] = formatless_isbns.first.delete("-")
        end

        resource_type = monograph_doc['resource_type_tesim']&.map(&:strip)&.reject(&:blank?)&.first&.downcase
        counter_data_type = 'Book'

        tsv << [monograph_doc.id,
                monograph_doc.id,
                monograph_doc['title_tesim']&.first&.squish,
                monograph_doc['creator_ss'],
                monograph_doc['date_created_tesim']&.first,
                monograph_doc['doi_ssim']&.first,
                monograph_doc['identifier_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; '),
                resource_type,
                counter_data_type,
                monograph_doc['all_isbns_for_siq'], # this isn't currently used by SiQ, but may be in the future
                monograph_doc['primary_isbn_for_siq']]
      end

      file_set_docs.each do |file_set_doc|
        resource_type = file_set_doc['resource_type_tesim']&.map(&:strip)&.reject(&:blank?)&.first&.downcase

        kind = FeaturedRepresentative.where(file_set_id: file_set_doc.id).first&.kind
        monograph_doc = monograph_docs.find { |doc| doc.id == file_set_doc['monograph_id_ssim']&.first }

        counter_data_type = if kind.present?
                              if ['audiobook', 'epub', 'mobi', 'pdf_ebook'].include?(kind)
                                'Book'
                              elsif ['database'].include?(kind)
                                'Dataset'
                              elsif ['webgl'].include?(kind)
                                'Interactive_Resource'
                              else
                                'Other'
                              end
                            else
                              if file_set_doc['hidden_representative_bsi'] == true
                                'Image' # has to be a cover image here
                              end
                            end

        counter_data_type = RESOURCE_TYPE_TO_COUNTER_DATA_TYPE_MAP[resource_type] if counter_data_type.blank?

        tsv << [file_set_doc.id,
                file_set_doc['monograph_id_ssim']&.first,
                file_set_doc['title_tesim']&.first&.squish,
                file_set_doc['creator_ss'],
                monograph_doc.present? ? monograph_doc['date_created_tesim']&.first : nil,
                file_set_doc['doi_ssim']&.first,
                file_set_doc['identifier_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; '),
                resource_type,
                counter_data_type,
                monograph_doc.present? ? monograph_doc['all_isbns_for_siq'] : nil,
                monograph_doc.present? ? monograph_doc['primary_isbn_for_siq'] : nil]
      end

      # now write all EbookTableOfContentsCache objects, pulled from MySQL, as our COUNTER "Book Segments"
      EbookTableOfContentsCache.all.each do |toc_row|
        toc_json = toc_row.toc
        next if toc_json.blank?

        fr = FeaturedRepresentative.where(file_set_id: toc_row.noid)&.first
        # the FeaturedRepresentative for this EbookTableOfContentsCache row may have been deleted, hence the else fallback
        monograph_id = if fr.present?
                         fr.work_id
                       else
                         monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{toc_row.noid}", rows: 1, fl: ['monograph_id_ssim'])&.first
                         monograph_doc.present? ? monograph_doc['monograph_id_ssim']&.first : nil
                       end

        monograph_doc = monograph_id.nil? ? nil : monograph_docs.find { |doc| doc.id == monograph_id } || nil

        # we have EbookTableOfContentsCache entries for deleted ebooks, which may be from deleted Monographs
        # these should be retained, I guess, for future reprocessing of historic COUNTER events, but we can't
        # pull Monograph metadata from Solr records that no longer exist
        # Sometimes we get orphaned ebooks, which would also have the same problem
        monograph_date_created = monograph_doc.blank? ? nil : monograph_doc['date_created_tesim']&.first
        monograph_isbn = monograph_doc.blank? ? nil : monograph_doc['all_isbns_for_siq']
        monograph_primary_isbn = monograph_doc.blank? ? nil : monograph_doc['primary_isbn_for_siq']

        JSON.parse(toc_json).each_with_index do |entry, index|
          book_segment_id = toc_row.noid + '.' + (index + 1).to_s.rjust(4, '0')
          book_segment_title = entry['title'].present? ? entry['title'].gsub(/[^\w\s]/, '').squish : nil

          tsv << [book_segment_id, toc_row.noid, book_segment_title, nil, monograph_date_created, nil, nil, nil, 'Book_Segment', monograph_isbn, monograph_primary_isbn]
        end

        # in the event there is a MOBI sibling to an EPUB we're working on, we'll write the entries out again...
        # for the MOBI, which we do not unpack or store in EbookTableOfContentsCache. Purely for count explosion purposes.
        mobi_fr = FeaturedRepresentative.where(work_id: monograph_id, kind: 'mobi')&.first

        if fr&.kind == 'epub' && mobi_fr.present?
          mobi_id = mobi_fr.file_set_id
          # pure duplicate of the above loop with the mobi_id instead of the epub_id
          JSON.parse(toc_json).each_with_index do |entry, index|
            book_segment_id = mobi_id + '.' + (index + 1).to_s.rjust(4, '0')
            book_segment_title = entry['title'].present? ? entry['title'].gsub(/[^\w\s]/, '').squish : nil

            tsv << [book_segment_id, mobi_id, book_segment_title, nil, monograph_date_created, nil, nil, nil, 'Book_Segment', monograph_primary_isbn, monograph_primary_isbn]
          end
        end

        # in the event there is an audiobook sibling to an EPUB we're working on, we'll write the entries out again...
        # for the audiobook, which we do not unpack or store in EbookTableOfContentsCache. Purely for count explosion purposes.
        audiobook_fr = FeaturedRepresentative.where(work_id: monograph_id, kind: 'audiobook')&.first

        if fr&.kind == 'epub' && audiobook_fr.present?
          audiobook_id = audiobook_fr.file_set_id
          # pure duplicate of the above loop with the audiobook_id instead of the epub_id/mobi_id
          JSON.parse(toc_json).each_with_index do |entry, index|
            book_segment_id = audiobook_id + '.' + (index + 1).to_s.rjust(4, '0')
            book_segment_title = entry['title'].present? ? entry['title'].gsub(/[^\w\s]/, '').squish : nil

            tsv << [book_segment_id, audiobook_id, book_segment_title, nil, monograph_date_created, nil, nil, nil, 'Book_Segment', monograph_primary_isbn, monograph_primary_isbn]
          end
        end
      end
    end
    # puts "Item data for ScholarlyIQ saved to #{output_file}"

    fail unless scholarlyiq_s3_deposit(output_file)

    # No real purpose keeping this, the DB records are sticking around anyways!
    # Deleting it means the crons can use system /tmp for these. No chance of trying to save to a missing/broken mount.
    File.delete(output_file)
  end

  # TODO: put these into a service that can be used both here and in BuildKbartJob, and maybe elsewhere too.
  # See https://mlit.atlassian.net/browse/HELIO-4755
  def print_isbn(isbns)
    priority_list = {
      "hardcover" => 1,
      "hardback" => 2, # added vs BuildKbartJob
      "cloth" => 3,
      "Hardcover" => 4,
      "print" => 5,
      "hardcover : alk. paper" => 6,
      "hc. : alk. paper" => 7,
      "paperback" => 8,
      "paper" => 9,
      "Paper" => 10,
      "pb." => 11,
      "pb. : alk. paper" => 12,
      "paper with cd" => 13,
      "paper plus cd rom" => 14
    }

    priority_isbn(isbns, priority_list)
  end

  def online_isbn(isbns)
    # Prefer OA ISBNs over other kinds
    priority_list = {
      "open access" => 1,
      "open-access" => 2,
      "OA" => 3,
      "ebook" => 4,
      "e-book" => 5,
      "epub" => 6, # added vs BuildKbartJob
      "ebook epub" => 7,
      "PDF" => 8,
      "ebook pdf" => 9,
      "pdf" => 10
    }

    priority_isbn(isbns, priority_list)
  end

  # this differs from the one in BuildKbartJob in that it accounts for non-breaking spaces in data
  def priority_isbn(isbns, priority_list)
    results = {}
    isbns.each do |isbn|
      # normal entries look like:
      # ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (open access)"]
      matches = isbn.match(/^(.*)\s*\((.*)\)/)
      # There are some isbns (like 15 maybe) that don't have a (type) and look like:
      # "9780262512503", "9780262730068", "9780262230032"
      # And we know that some heb monographs don't have an ISBN at all. If there's no type, just return nothing,
      # as we would do for books that have no ISBN. Seems like it's better to return nothing than the wrong thing.
      if matches.present?
        isbn_numbers = matches[1].delete("-")
        type = matches[2]
        results[priority_list[type]] = isbn_numbers
      end
    end

    # this is... kind of ugly. It returns the top "priority" isbn if it can find one
    results.delete(nil)
    return "" if results.empty?

    results.sort_by { |k, v| k }&.first[1] || ""
  end
end
