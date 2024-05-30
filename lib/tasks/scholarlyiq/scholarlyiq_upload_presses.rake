# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Upload Press Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_presses, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_presses[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # For now let's assume these will be tidied up manually, or by a separate cron
    output_file = File.join(args.output_directory, "presses-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")

    CSV.open(output_file, "w", col_sep: "\t", write_headers: true) do |tsv|
      tsv << %w[press_id subdomain name child_press_ids]
      Press.all.each do |press|
        tsv << [
          press.id,
          press.subdomain,
          press.name,
          press.children.map(&:id).join(",")
        ]
      end
    end

    puts "Press data for ScholarlyIQ saved to #{output_file}"
    fail unless scholorlyiq_s3_deposit(output_file)
  end
end