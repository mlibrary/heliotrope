# frozen_string_literal: true

# We're need to use the Clamby gem instead of ClamAV gem as the latter no longer builds:https://github.com/eagleas/clamav/issues/11
# https://github.com/eagleas/clamav/issues/11
# I think probably Hyrax will swtich to clamby in version 4.0 but I'm not clear on it.
# See https://github.com/samvera/hydra-works/blob/master/lib/hydra/works/virus_scanner.rb and HELIO-3230

if defined?(Clamby)
  # https://github.com/kobaltz/clamby#configuration
  Clamby.configure(
    check: false,
    # daemonize: true,
    output_level: 'medium',
    fdpass: true
  )
end
