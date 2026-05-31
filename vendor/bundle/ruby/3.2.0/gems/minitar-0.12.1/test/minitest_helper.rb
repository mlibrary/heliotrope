# frozen_string_literal: true

require "fileutils"
require "minitar"

gem "minitest"
require "minitest/autorun"
require "minitest/focus"

Dir.glob(File.join(File.dirname(__FILE__), "support/*.rb")).sort.each do |support|
  require support
end
