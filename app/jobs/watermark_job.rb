
# frozen_string_literal: true

require 'open3'

class WatermarkJob < ApplicationJob
  def perform(opts)
    file_path = opts[:file_path]
    stamp_file_path = opts[:stamp_file_path]
    stamped_file_path = opts[:stamped_file_path]
    session_id = opts[:session_id]
    cache_key = opts[:cache_key]
    download_path = opts[:download_path]

    command = "pdftk #{file_path} stamp #{stamp_file_path} output #{stamped_file_path}"

    stdin, stdout, stderr, wait_thr = Open3.popen3(command)
    stdin.close
    stdout.binmode
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close

    channel_name = "long_running_requests_channel_#{session_id}"

    unless wait_thr.value.success?
      message = "Unable to execute command \"#{command}\"\n#{err}\n#{out}"
      ActionCable.server.broadcast channel_name, { error: message }
      raise "#{message}"
    else
      Rails.cache.write(cache_key, IO.binread(stamped_file_path), expires_in: 30.days)
      # You can't send the download over a web socket, so we'll redirect back to the download page
      # now that the watermarked pdf has been cached
      Rails.logger.debug { "#{cache_key} cached" }
      Rails.logger.debug { "sending broadcast to #{channel_name}" }
      ActionCable.server.broadcast channel_name, { download_url: download_path }
    end
  end
end
