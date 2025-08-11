# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Upload COUNTER Reports Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_counter_reports, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_counter_reports[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # just want to do this once and use it to get the press subdomain URL for all COUNTER "search" rows
    press_map = {}
    Press.all.map { |press| press_map[press.id] = press.subdomain }

    # These files are named to indicate the dates of the actual records (yesterday)
    output_file = File.join(args.output_directory, "counter_reports-#{Time.now.days_ago(1).getlocal.strftime("%Y-%m-%d")}.tsv")

    CSV.open(output_file, "w", col_sep: "\t") do |tsv|
      # find_each should default to 1000 rows stored at a time, not gobbling up RAM for the entire resultset
      CounterReport.where("created_at >= CURDATE() - INTERVAL 1 DAY AND created_at < CURDATE()").find_each.with_index do |row, index|
        # For now, `url` is a shimmed-in addition but we may start adding it "properly" on new table rows in the future
        if index.zero?
          header = (row.attributes.map { |key, _value| key }) << 'url'
          tsv << header
        else
          # `squish` to remove wacky line endings like solo carriage returns which corrupt the TSV by overwriting the...
          #  start of the line
          # `is_a?(String)` to avoid quoting empty cells, which causes altered output in Scholarly iQ's reports, i.e.
          # blanks normally become - (hyphen) but a set of double quotes is taken as an actual value on ingest.
          row_data = row.attributes.map do |key, value|
            if value.is_a?(String)
              if key == 'noid' && row['book_segment'].present?
                # for convenience on SiQ's side, we're adding the book segment to the Noid which will become their unique "ItemID" which is used for double-click detection etc
                value.squish + '.' + row['book_segment'].to_s.rjust(4, '0')
              else
                value.squish
              end
            else
              # leave NULLs/nils as "just a tab" in the TSV
              value
            end
          end

          row_data << counter_row_url(row, press_map)
          tsv << row_data
        end
      end
    end
    # puts "COUNTER report data for ScholarlyIQ saved to #{output_file}"

    # these are deleted from the S3 bucket after 60 days, using a Lifecycle Rule
    fail unless scholarlyiq_s3_deposit(output_file)

    # No real purpose keeping this, the DB records are sticking around anyways!
    # Deleting it means the crons can use system /tmp for these. No chance of trying to save to a missing/broken mount.
    File.delete(output_file)
  end

  def counter_row_url(row, press_map)
    if row[:noid].present?
      "https://hdl.handle.net/2027/fulcrum.#{row[:noid]}"
    else
      "https://www.fulcrum.org/#{press_map[row[:press]]}"
    end
  end
end
