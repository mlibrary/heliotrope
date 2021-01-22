# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Yabeda::Prometheus::Exporter

Dir[File.join(ENV.fetch("PROMETHEUS_MONITORING_DIR"), "*.bin")].each do |file_path|
  File.unlink(file_path)
end

run Rails.application
