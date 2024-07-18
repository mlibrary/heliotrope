# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Upload COUNTER Reports Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_counter_reports, [:output_directory, :all_rows] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_counter_reports[output_directory, <all_rows>]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # this optional parameter will very rarely be used, maybe twice as we start up the Scholarly iQ feeds
    all_rows = args.all_rows == 'all_rows'

    # For now let's assume these will be tidied up manually, or by a separate cron
    output_file = if all_rows
                    File.join(args.output_directory, "counter_reports_all_rows-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")
                  else
                    # note this is named to indicate the dates of the actual records
                    File.join(args.output_directory, "counter_reports-#{Time.now.days_ago(1).getlocal.strftime("%Y-%m-%d")}.tsv")
                  end

    # find_each should default to 1000 rows stored at a time, not gobbling up RAM for the entire resultset
    rows = if all_rows
             CounterReport.find_each
           else
             CounterReport.where("created_at >= CURDATE() - INTERVAL 1 DAY AND created_at < CURDATE()").find_each
           end

    CSV.open(output_file, "w", col_sep: "\t", force_quotes: true, write_headers: true) do |tsv|
      rows.with_index do |row, index|
        if index.zero?
          tsv << row.attributes.map { |key, _value| key }
        else
          tsv << row.attributes.map { |_key, value| value }
        end
      end
    end
    # puts "COUNTER report data for ScholarlyIQ saved to #{output_file}"

    fail unless scholarlyiq_s3_deposit(output_file)

    # No real purpose keeping this, the DB records are sticking around anyways!
    # Deleting it means the crons can use system /tmp for these. No chance of trying to save to a missing/broken mount.
    File.delete(output_file)
  end
end
