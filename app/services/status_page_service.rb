# frozen_string_literal: true

require 'benchmark'

module StatusPageService
  include Skylight::Helpers

  instrument_method
  def resque_workers_count
    Resque.workers.count
  end

  instrument_method
  def resque_workers_working_count
    Resque.workers.select { |w| w.working? }.count
  end

  instrument_method
  def server_status
    `uptime`&.strip
  end

  instrument_method
  def redis
    # Storing/retrieving an actual value might be better. This is good enough for now.
    redis = if Settings.host == "www.fulcrum.org" || Settings.host == "staging.fulcrum.org" # # HELIO-4477
              Redis.new(host: "redis", port: 6379)
            else
              Redis.new(host: "localhost", port: 6379)
            end
    result = redis.ping == "PONG" ? 'UP' : 'DOWN'
    redis.quit
    result
  end

  # this is listed as a "MySQL" check in the output, which I think is fair enough
  instrument_method
  def check_active_record
    ActiveRecord::Migrator.current_version
    'UP'
  rescue StandardError => _e
    'DOWN'
  end

  instrument_method
  def check_config_file(filename)
    file = Rails.root.join('config', filename)
    return 'NOT FOUND' unless File.exist?(file)
    # not using `safe_load` to avoid `Psych::BadAlias: Unknown alias` stuff.
    yaml = YAML.load(File.read(file)) if File.exist?(file)
    yaml.present? ? 'OK' : 'ERROR'
  rescue StandardError => _e
    'ERROR'
  end

  instrument_method
  def helio_processes
    @helio_processes ||= `ps -f -u $USER`.split("\n")
  end

  instrument_method
  def puma_workers
    helio_processes&.grep(/puma/)&.join("\n") || 'NONE FOUND'
  end

  instrument_method
  def resque_workers
    helio_processes&.grep(/resque/)&.join("\n") || 'NONE FOUND'
  end

  instrument_method
  def fedora
    file = Rails.root.join('config', 'fedora.yml')
    return 'YML CONFIG NOT FOUND' unless File.exist?(file)
    url = YAML.load(ERB.new(File.read(file)).result)[Rails.env]['url']
    `curl --max-time 5 -s -o /dev/null -w "%{http_code}" '#{url}'` == '200' ? 'UP' : 'DOWN'
  end

  instrument_method
  def solr
    file = Rails.root.join('config', 'solr.yml')
    return 'YML CONFIG NOT FOUND' unless File.exist?(file)
    parts = YAML.load(ERB.new(File.read(file)).result)[Rails.env]['url'].split("/solr/")
    url = parts[0]
    core = parts[1]
    conn = RSolr.connect url: url

    r = conn.get "/solr/admin/cores", params: { action: "STATUS", core: core }
    output = r.response[:status] == 200 ? 'UP' : 'DOWN'
    output += r["status"][core].include?("instanceDir") ? " - core (#{core}) found" : " - core (#{core}) NOT found"

    r = conn.get "/solr/admin/info/system"
    output += r["lucene"]["solr-spec-version"].present? ? " - version: #{r['lucene']['solr-spec-version']}" : " - version NOT found"
    output
  rescue StandardError => e
    Rails.logger.error("[StatusPageService Solr Error] #{e}")
    'DOWN'
  end

  # Not sure how useful this will be. This book has 2000 or so file sets so maybe a long response time?
  # HELIO-4562
  def solr_sample_query
    time = Benchmark.measure do
      ActiveFedora::SolrService.query("Brushed in Light Calligraphy in East Asian Cinema", df: 'title_tesim', rows: 1)
    end
    time.real
  end

  instrument_method
  def fits_version
    output = `fits.sh -v`&.strip
    output.presence || 'NOT FOUND'
  end

  instrument_method
  def shib_process
    if `ps -ef | pgrep shibd`.include?("\n")
      'currently running'
    else
      'not currently running'
    end
  end

  instrument_method
  def shib_check_redirecting
    expected_redirect_location = 'https://www.fulcrum.org/Shibboleth.sso/Login?target=https%3A%2F%2Fwww.fulcrum.org%2Fshib_session&entityID=https%3A%2F%2Fshibboleth.umich.edu%2Fidp%2Fshibboleth'
    uri = URI('https://www.fulcrum.org/shib_login')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 5)
    request = Net::HTTP::Get.new uri
    response = http.request request
    # https://docs.ruby-lang.org/en/2.5.0/Net/HTTP.html
    (response.kind_of? Net::HTTPFound) && response['location'] == expected_redirect_location ? 'UP' : 'DOWN'
  end

  instrument_method
  def derivatives_path
    if Settings.derivatives_path.present?
      time = Benchmark.measure do
        `/bin/ls #{Settings.derivatives_path} > /dev/null 2> /dev/null`
      end
      time.real
    else
      "missing"
    end
  end

  instrument_method
  def uploads_path
    if Settings.uploads_path.present?
      time = Benchmark.measure do
        `/bin/ls #{Settings.uploads_path} > /dev/null 2> /dev/null`
      end
      time.real
    else
      "missing"
    end
  end

  instrument_method
  def riiif_network_files_path
    if Settings.riiif_network_files_path.present?
      time = Benchmark.measure do
        `/bin/ls #{Settings.riiif_network_files_path} > /dev/null 2> /dev/null`
      end
      time.real
    else
      "missing"
    end
  end

  instrument_method
  def scratch_space_path
    if Settings.scratch_space_path.present?
      time = Benchmark.measure do
        `/bin/ls #{Settings.scratch_space_path} > /dev/null 2> /dev/null`
      end
      time.real
    else
      "missing"
    end
  end
end
