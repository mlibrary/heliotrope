# frozen_string_literal: true

require 'open3'

class WatermarkJob < ApplicationJob
  def perform(command, status, cache_key, stamped_file_path)
    stdin, stdout, stderr, wait_thr = Open3.popen3(command)
    stdin.close
    stdout.binmode
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close

    unless wait_thr.value.success?
      message = "Unable to execute command \"#{command}\"\n#{err}\n#{out}"
      status.error = true
      status.error_message = message
      status.completed = true
      status.save
      raise "#{message}"
    else
      Rails.cache.write(cache_key, IO.binread(stamped_file_path), expires_in: 30.days)
      status.completed = true
      status.save
    end
  end
end
