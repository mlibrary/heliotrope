# frozen_string_literal: true

include StatusPageService

class UtilitiesController < ApplicationController
  def whoami # rubocop:disable Metrics/CyclomaticComplexity
    headers = request.headers
    hash_tag_line = ''
    80.times { hash_tag_line += '#' }
    who_am_i = <<~WHO_AM_I
      #{hash_tag_line}
      #
      # Fulcrum.org Client Identification Utility (Who am I?)
      #
      #{hash_tag_line}

      To us, you appear to be

        ...running a browser named    #{headers['User-Agent']}
        ...on a workstation named     #{headers['Remote-Host']}
        ...with an IP address of      #{headers['Remote-Addr']}
        ...or possibly                #{headers['X-Forwarded-For']}
        ...and authenticated as       #{headers['Remote-User']}

      The note you just left
      for the administrator
      to trace this access is         #{headers['Query-String'].presence || '(none)'}**

      #{hash_tag_line}
      #
      #  How you should use this information:
      #
      #    The information above should be shared with technical staff at
      #    your site in order to help troubleshoot questions about
      #
      #    o configuration of IP addresses at your institution
      #    o configuration of proxy servers at your institution or Internet
      #      Service Provider
      #
      #    Note: if you are having access problems, do not assume that the
      #    IP address given above should be permitted for the resource.
      #    You *must* share this information with technical staff familiar
      #    with your institution's network in order to determine how to
      #    solve your access problem.
      #
      #  ** Your content provider may instruct you to leave a one-word note
      #     for the web administrator so that this access can be traced for
      #     troubleshooting purposes.
      #
      #     To leave a note, simply access
      #
      #     https://fulcurm.org/whoami?note
      #
      #     replacing the word 'note' with a single word of your own choosing
      #     then tell your content provider.
      #
      #{hash_tag_line}
    WHO_AM_I
    render plain: who_am_i
  end

  def status
    hash_tag_line = ''
    130.times { hash_tag_line += '#' }
    app_status = <<~APP_STATUS
      #{hash_tag_line}
      #
      # Fulcrum.org App and Environment status page
      #
      #{hash_tag_line}

      Application Checks

        Config Files

          database.yml .......... #{check_config_file('database.yml')}
          fedora.yml ............ #{check_config_file('fedora.yml')}
          secrets.yml ........... #{check_config_file('secrets.yml')}
          solr.yml .............. #{check_config_file('solr.yml')}
          analytics.yml ......... #{check_config_file('analytics.yml')}
          aptrust.yml ........... #{check_config_file('aptrust.yml')}
          blacklight.yml ........ #{check_config_file('blacklight.yml')}
          box.yml ............... #{check_config_file('box.yml')}
          crossref.yml .......... #{check_config_file('crossref.yml')}
          redis.yml ............. #{check_config_file('redis.yml')}
          resque-pool.yml ....... #{check_config_file('resque-pool.yml')}
          role_map.yml .......... #{check_config_file('role_map.yml')}
          skylight.yml .......... #{check_config_file('skylight.yml')}

        Resque workers .......... #{resque_workers_count} registered, #{resque_workers_working_count} working


      Environment Status

          Shibboleth ............ #{shib_check_redirecting}
          MySQL ................. #{check_active_record}
          Fedora ................ #{fedora}
          Solr .................. #{solr}
          Redis ................. #{redis}
          FITS .................. #{fits_version}
    APP_STATUS

    if current_ability&.current_user&.platform_admin?
      app_status += <<~APP_STATUS


      Server Uptime

        #{server_status}


      Processes - Puma workers

        #{puma_workers}


      Processes - Resque workers

        #{resque_workers}


      ActiveFedora - Connection config options

        #{ActiveFedora::Fedora.instance.authorized_connection.options}

      APP_STATUS
    end

    app_status += "\n#{hash_tag_line}"

    render plain: app_status
  end

  def ableplayer
    render layout: false
  end
end
