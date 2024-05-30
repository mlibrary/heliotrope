# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Upload Institutions Data to S3 Bucket For ScholarlyIQ'
namespace :heliotrope do
  task :scholarlyiq_upload_institutions, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:scholarlyiq_upload_institutions[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    # For now let's assume these will be tidied up manually, or by a separate cron
    output_file = File.join(args.output_directory, "institutions-#{Time.now.getlocal.strftime("%Y-%m-%d")}.tsv")

    CSV.open(output_file, "w", col_sep: "\t", write_headers: true) do |tsv|
      tsv << %w[identifier name display_name entity_id]
      Greensub::Institution.all.each do |institution|
        tsv << [institution.identifier, institution.name, institution.display_name, institution.entity_id]
      end
    end

    puts "Institution data for ScholarlyIQ saved to #{output_file}"
    fail unless scholorlyiq_s3_deposit(output_file)
  end

  # Because of the way task namespacing works, this should be usable by the other ScholarlyIQ tasks
  def scholorlyiq_s3_deposit(filename)
    success = false
    begin
      scholorlyiq_yaml = Rails.root.join('config', 'scholorlyiq.yml')
      scholorlyiq = YAML.safe_load(File.read(scholorlyiq_yaml))
      Aws.config.update(credentials: Aws::Credentials.new(scholorlyiq['AwsAccessKeyId'], scholorlyiq['AwsSecretAccessKey']))
      s3 = Aws::S3::Resource.new(region: scholorlyiq['BucketRegion'])
      success = s3.bucket(scholorlyiq['Bucket']).object(File.basename(filename)).upload_file(filename)
    rescue Aws::S3::Errors::ServiceError => e
      puts "Upload of file #{filename} failed in #{e.context} with error #{e}"
      success = false
    end
    success
  end
end
