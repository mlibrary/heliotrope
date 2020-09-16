# frozen_string_literal: true

class RecacheCounterRobotsJob < ApplicationJob
  JSON_FILE = Rails.root.join('tmp', 'counter-robots.json')
  DOWNLOAD_CMD = "curl --silent https://raw.githubusercontent.com/atmire/COUNTER-Robots/master/COUNTER_Robots_list.json > #{JSON_FILE}"
  RAILS_CACHE_KEY = 'counter_robots'

  def perform
    return false unless download_json
    return false unless cache_pattern_list
    true
  end

  def self.system_call(command)
    system(command)
  end

  def download_json
    command = DOWNLOAD_CMD
    rvalue = self.class.system_call(command)
    return true if rvalue
    case rvalue
    when false
      Rails.logger.error("ERROR Command #{command} error code #{self.class.system_call($?)}")
    else
      Rails.logger.error("ERROR Command #{command} not found #{self.class.system_call($?)}")
    end
    false
  end

  def load_list
    rvalue = []
    if File.exist?(JSON_FILE)
      begin
        rvalue = File.open(JSON_FILE, 'r') do |file|
                   JSON.load file || []
                 end
      rescue StandardError => e
        Rails.logger.error("ERROR: RecacheCounterRobotsJob#load_list raised #{e}")
      end
    end
    rvalue.map { |entry| entry["pattern"] }
  end

  def cache_pattern_list
    Rails.cache.write(RAILS_CACHE_KEY, load_list, expires_in: 7.days)
    true
  end
end
