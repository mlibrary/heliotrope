# frozen_string_literal: true

desc 'Stream FeaturedRepresentative files for a press subdomain to a local directory'
namespace :heliotrope do
  task :output_press_representatives_by_kind, [:subdomain, :featured_representative_kind, :directory] => :environment do |_t, args|
    # Usage:
    #   bundle exec rails "heliotrope:output_press_representatives_by_kind[subdomain, epub, /a_writable_folder]"

    subdomain = args.subdomain
    kind      = args.featured_representative_kind
    directory = args.directory

    if Press.find_by(subdomain: subdomain).blank?
      puts "Provided subdomain (#{subdomain}) does not exist. Exiting."
      exit
    end

    unless FeaturedRepresentative::KINDS.include?(kind)
      puts "Provided featured_representative_kind (#{kind}) is not valid. Must be one of: #{FeaturedRepresentative::KINDS.join(', ')}. Exiting."
      exit
    end

    unless File.directory?(directory)
      puts "Provided directory (#{directory}) does not exist. Exiting."
      exit
    end

    unless File.writable?(directory)
      puts "Provided directory (#{directory}) is not writable. Exiting."
      exit
    end

    puts "Querying Solr for Monographs in press '#{subdomain}'..."
    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{subdomain}", rows: 100_000)
    monograph_ids = docs.map(&:id)

    if monograph_ids.empty?
      puts "No Monographs found for press '#{subdomain}'. Exiting."
      exit
    end

    puts "Found #{monograph_ids.count} Monograph(s). Looking up FeaturedRepresentative file sets..."
    file_set_ids = FeaturedRepresentative.where(work_id: monograph_ids, kind: kind).pluck(:file_set_id)

    if file_set_ids.empty?
      puts "No FeaturedRepresentative records of kind '#{kind}' found for press '#{subdomain}'. Exiting."
      exit
    end

    puts "Found #{file_set_ids.count} file set(s) of kind '#{kind}'. Streaming files to #{directory}..."

    file_set_ids.each do |file_set_id|
      file_set = FileSet.find(file_set_id)
      original_file = file_set.original_file

      filename = CGI.unescape(original_file.original_name.to_s)
      if filename.blank?
        puts "  [SKIP] FileSet #{file_set_id} has no original filename. Skipping."
        next
      end

      dest_path = File.join(directory, filename)

      if File.exist?(dest_path)
        puts "  [SKIP] File already exists, skipping to avoid overwrite: #{dest_path}"
        next
      end

      begin
        File.open(dest_path, "wb") do |dest|
          original_file.stream.each { |chunk| dest.write(chunk) }
        end
        puts "  [OK]   #{filename} (FileSet #{file_set_id})"
      rescue NoMemoryError => e
        puts "  [ERROR] NoMemoryError streaming FileSet #{file_set_id}: #{e.message}"
      rescue StandardError => e
        puts "  [ERROR] Failed to write #{filename} (FileSet #{file_set_id}): #{e.message}"
      end
    end

    puts "Done."
  end
end

