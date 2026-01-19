# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# For HELIO-2488
# HELIO-3118
# HELIO-3877

# Creates a report of handles => dois that will
# be ingested into TMM so that TMM can know the
# handle that Fulcrum has assigned to a Monograph

# UPDATE: due to HELIO-3877 we're doing fulcrum urls => dois
# No more handles.

desc 'monograph handles and DOIs for certain presses'
namespace :heliotrope do
  task :fulcrum_dois, [:path] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:fulcrum_dois[/a_writable_folder_or_full_file_path]"
    unless File.writable?(args.path) || File.writable?(File.dirname(args.path))
      puts "(#{args.path}) is not writable. You must provide a writable directory or file path. Exiting."
      exit
    end

    # You can put child presses here, or not.
    # If you don't it will automatically pick up the children of a press.
    subdomains = [
      "amherst",
      "atg",
      "barpublishing",
      "cb",
      "cjs",
      "csas",
      "cseas",
      "cv",
      "leverpress",
      "livedplaces",
      "lrcss",
      "michelt",
      "michigan",
      "mps",
      "westminster"
    ]

    children = []
    subdomains.each do |subdomain|
      children << Press.where(subdomain: subdomain).first&.children&.pluck(:subdomain)
    end

    subdomains = subdomains + children
    subdomains = subdomains.flatten.compact.uniq

    hits = ActiveFedora::SolrService.query("{!terms f=press_sim}#{subdomains.map(&:downcase).join(',')}", rows: 100_000)

    if hits.count.zero?
      puts "No Monographs found. Nothing to output."
      exit
    end

    file_path = File.directory?(args.path) ? File.join(args.path, 'fulcrum_dois.csv') : args.path

    CSV.open(file_path, "w") do |csv|
      hits.each do |hit|
        presenter = Hyrax::MonographPresenter.new(SolrDocument.new(hit), nil)
        url = Rails.application.routes.default_url_options[:protocol] + "://" + Rails.application.routes.default_url_options[:host] + Rails.application.routes.url_helpers.hyrax_monograph_path(presenter.id)
        csv << [url, presenter.doi_url, presenter.subdomain, presenter.visibility]
      end
    end

    puts "#{hits.count} handles have been output to #{file_path}"

    yaml = Rails.root.join('config', 'firebrand_sftp.yml')
    fail "FTP YML config file not found at '#{yaml}'" unless File.exist? yaml
    config = YAML.safe_load(File.read(yaml))

    firebrand_sftp = config['firebrand_sftp_credentials']
    begin
      Net::SFTP.start(firebrand_sftp["sftp"], firebrand_sftp["user"], password: firebrand_sftp["password"]) do |sftp|
        puts "Uploading '#{file_path}' to sftp://hosted.ftp.firebrandtech.com (destination directory 'ToTMM')"
        # RE: `File.basename` - the script is written to let the user choose a specific output file *path* if desired.
        # So just covering that even though our only usage of this (in a cron) provides a directory and so uses the...
        # default file name of `fulcrum_dois.csv`.
        sftp.upload!(file_path, "ToTMM/#{File.basename(file_path)}")
      end
    rescue RuntimeError, Net::SFTP::StatusException => e
      fail "SFTP ERROR: #{e}"
    end
  end
end
