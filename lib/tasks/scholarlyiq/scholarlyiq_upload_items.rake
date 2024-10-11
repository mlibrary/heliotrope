# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# "Items" refers to objects, a.k.a. Monographs and FileSets
desc 'Upload Items Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_items, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_items[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # For now let's assume these will be tidied up manually, or by a separate cron
    output_file = File.join(args.output_directory, "items-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")

    docs = ActiveFedora::SolrService.query('+(has_model_ssim:Monograph OR has_model_ssim:FileSet)',
                                           fl: ['id',
                                                'title_tesim',
                                                'creator_ss',
                                                'date_created_tesim',
                                                'doi_ssim',
                                                'identifier_tesim',
                                                'resource_type_tesim',
                                                'isbn_tesim'], rows: 100_000)

    CSV.open(output_file, "w", col_sep: "\t") do |tsv|
      tsv << %w[id title creator date_created doi identifier resource_type isbn primary_isbn]
      docs.each do |doc|
        isbns = doc['isbn_tesim']&.map(&:strip)&.reject(&:blank?)

        primary_isbn = if isbns.present?
                         # these methods return "" if they can't find anything (which is truthy)
                         online_isbn(isbns).presence || print_isbn(isbns).presence
                       else
                         nil
                       end

        # the copied-from-BuildKbartJob methods above return "" if they have no recognized format etc, but we'll just...
        # grab any isbn that may be left over, sans the format bit, for SiQ if we end up here
        if primary_isbn.blank? && isbns.present?
          formatless_isbns = isbns.map { |val| val&.strip&.sub(/\s*\(.+\)$/, '')&.strip }
          primary_isbn = formatless_isbns.first.delete("-")
        end

        tsv << [doc.id,
                doc['title_tesim']&.first&.squish,
                doc['creator_ss'],
                doc['date_created_tesim']&.first,
                doc['doi_ssim']&.first,
                doc['identifier_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; '),
                doc['resource_type_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; '),
                isbns&.join('; '),
                primary_isbn]
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
      "paper plus cd rom" => 14,
      "print" => 15 # added vs BuildKbartJob
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
