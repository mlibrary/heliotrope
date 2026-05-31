# frozen_string_literal: true

require "rubygems"
require "bundler"
require "coveralls"

Bundler.require(:default, :test)

Coveralls.wear!

require File.expand_path("./util/bagit_matchers", File.dirname(__FILE__))

RSpec.configure do |config|
  config.include(BagitMatchers)
end

$LOAD_PATH.unshift File.expand_path("../lib", File.dirname(__FILE__))
require "bagit"

require "tempfile"

class Sandbox
  def initialize
    tf = Tempfile.open "sandbox"
    @path = tf.path
    tf.close!
    FileUtils.mkdir @path
  end

  def cleanup!
    FileUtils.rm_rf @path
  end

  def to_s
    @path
  end
end
