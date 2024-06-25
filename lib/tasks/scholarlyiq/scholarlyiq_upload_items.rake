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
                                                'resource_type_tesim'], rows: 100_000)

    CSV.open(output_file, "w", col_sep: "\t", write_headers: true) do |tsv|
      tsv << %w[id title creator date_created doi identifier resource_type]
      docs.each do |doc|
        tsv << [doc.id, doc['title_tesim']&.first,
                doc['creator_ss'],
                doc['date_created_tesim']&.first,
                doc['doi_ssim']&.first,
                doc['identifier_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; '),
                doc['resource_type_tesim']&.map(&:strip)&.reject(&:blank?)&.join('; ')]
      end
    end
    # puts "Item data for ScholarlyIQ saved to #{output_file}"

    fail unless scholarlyiq_s3_deposit(output_file)

    # No real purpose keeping this, the DB records are sticking around anyways!
    # Deleting it means the crons can use system /tmp for these. No chance of trying to save to a missing/broken mount.
    File.delete(output_file)
  end
end
