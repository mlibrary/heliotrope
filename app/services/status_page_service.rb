# frozen_string_literal: true

module StatusPageService
  def resque_workers_count
    Resque.workers.count
  end

  def resque_workers_working_count
    Resque.workers.select { |w| w.working? }.count
  end

  def server_status
    `uptime`&.strip
  end

  def redis
    # Storing/retrieving an actual value might be better. This is good enough for now.
    `redis-cli ping` == "PONG\n" ? 'UP' : 'DOWN'
  end

  # this is listed as a "MySQL" check in the output, which I think is fair enough
  def check_active_record
    ActiveRecord::Migrator.current_version
    'UP'
  rescue
    'DOWN'
  end

  def check_config_file(filename)
    file = Rails.root.join('config', filename)
    return 'NOT FOUND' unless File.exist?(file)
    # not using `safe_load` to avoid `Psych::BadAlias: Unknown alias` stuff.
    yaml = YAML.load(File.read(file)) if File.exist?(file)
    yaml.present? ? 'OK' : 'ERROR'
  rescue
    'ERROR'
  end

  def helio_processes
    @helio_processes ||= `ps -f -u $USER`.split("\n")
  end

  def puma_workers
    helio_processes&.grep(/puma/)&.join("\n") || 'NONE FOUND'
  end

  def resque_workers
    helio_processes&.grep(/resque/)&.join("\n") || 'NONE FOUND'
  end

  def fedora
    file = Rails.root.join('config', 'fedora.yml')
    return 'YML CONFIG NOT FOUND' unless File.exist?(file)
    url = YAML.load(ERB.new(File.read(file)).result)[Rails.env]['url']
    `curl --max-time 5 -s -o /dev/null -w "%{http_code}" '#{url}'` == '200' ? 'UP' : 'DOWN'
  end

  def solr
    file = Rails.root.join('config', 'solr.yml')
    return 'YML CONFIG NOT FOUND' unless File.exist?(file)
    url = YAML.load(ERB.new(File.read(file)).result)[Rails.env]['url'].sub('/solr/', '/solr/admin/cores?action=STATUS&core=')
    # single quotes to prevent incorrect url parsing (maybe) but definitely the `&` results in a background job otherwise
    response = `curl --max-time 5 -s -w "%{http_code}" '#{url}'`
    output = response.ends_with?('200') ? 'UP' : 'DOWN'
    output += response.include?('instanceDir') ? ' - core found' : ' - core not found'
    output
  rescue
    'ERROR'
  end

  def fits_version
    output = `fits.sh -v`&.strip
    output.presence || 'NOT FOUND'
  end

  def shib_check_redirecting
    expected_redirect_location = 'https://www.fulcrum.org/Shibboleth.sso/Login?target=https%3A%2F%2Fwww.fulcrum.org%2Fshib_session%3Flocale%3Den&entityID=https%3A%2F%2Fshibboleth.umich.edu%2Fidp%2Fshibboleth'
    uri = URI('https://www.fulcrum.org/shib_login')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 5)
    request = Net::HTTP::Get.new uri
    response = http.request request
    # https://docs.ruby-lang.org/en/2.5.0/Net/HTTP.html
    (response.kind_of? Net::HTTPFound) && response['location'] == expected_redirect_location ? 'UP' : 'DOWN'
  end
end
