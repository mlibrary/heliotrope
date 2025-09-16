# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Upload Book Segment Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_book_segments, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_book_segments[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    output_file = File.join(args.output_directory, "book_segments-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")

    CSV.open(output_file, "w", col_sep: "\t") do |tsv|
      tsv << %w[book_segment_id book_segment_title ebook_noid parent_noid]
      EbookTableOfContentsCache.all.each do |toc_row|
        toc_json = toc_row.toc
        next if toc_json.blank?

        monograph_id = FeaturedRepresentative.where(file_set_id: toc_row.noid)&.first&.work_id
        next if monograph_id.nil?

        JSON.parse(toc_json).each_with_index do |entry, index|
          book_segment_id = toc_row.noid + '.' + (index + 1).to_s.rjust(4, '0')
          book_segment_title = entry['title'].present? ? entry['title'].gsub(/[^\w\s]/, '').squish : nil

          tsv << [book_segment_id, book_segment_title, toc_row.noid, monograph_id]
        end
      end
    end
    # puts "Book segment data for ScholarlyIQ saved to #{output_file}"

    fail unless scholarlyiq_s3_deposit(output_file)

    # No real purpose keeping this, the DB records are sticking around anyways!
    # Deleting it means the crons can use system /tmp for these. No chance of trying to save to a missing/broken mount.
    File.delete(output_file)
  end
end
