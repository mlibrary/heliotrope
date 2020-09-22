# frozen_string_literal: true

desc 'Take any number of Monograph NOIDs and output CSV to update them'
namespace :heliotrope do
  task :monographs_output_csv_by_press, [:directory, :subdomain] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:monographs_output_csv_by_press[/a_writable_folder, subdomain]"

    if !File.writable?(File.dirname(args.directory))
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if Press.find_by(subdomain: args.subdomain).blank?
      puts "Provided subdomain (#{args.subdomain}) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "#{args.subdomain}_monograph_metadata_#{Time.now.strftime("%Y-%m-%d")}.csv")

    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.subdomain}", rows: 100_000)

    CSV.open(file_path, "w") do |csv|
      docs.each_with_index do |doc, index|
        exporter = Export::Exporter.new(doc.id, :monograph, system_metadata = true)
        exporter.write_csv_header_rows(csv) if index == 0
        csv << exporter.monograph_row
      end
    end
  end
end
