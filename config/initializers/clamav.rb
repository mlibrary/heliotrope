# frozen_string_literal: true

# ClamAV.instance.loaddb if defined? ClamAV

# We're overloading this to use the clamby gem instead of clamav gem
# I think probably Hyrax will swtich to clamby in version 3.0 but I'm not clear
# on it. We're doing it now (in 2.7.0).
# See https://github.com/samvera/hydra-works/blob/master/lib/hydra/works/virus_scanner.rb
# and HELIO-3230

if defined?(Clamby)
  # https://github.com/kobaltz/clamby#configuration
  Clamby.configure(
    check: false,
    # daemonize: true,
    output_level: 'medium',
    fdpass: true
  )
end

class HeliotropeVirusScanner < Hydra::Works::VirusScanner
  def infected?
    # my_result = Scanner.check_for_viruses(file)
    # [return true or false]
    scan_result = Clamby.virus?(file)
    warning("A virus was found in #{file}") if scan_result
    scan_result
  end
end

Hydra::Works.default_system_virus_scanner = HeliotropeVirusScanner if defined?(Clamby)
