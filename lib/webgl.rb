# frozen_string_literal: true

module Webgl
  require 'logger'

  @logger = Logger.new(STDOUT)

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  @root = './tmp/webgl'

  def self.root
    @root
  end

  def self.root=(path)
    @root = path
  end

  def self.path(id)
    File.join(root, id)
  end

  def self.path_entry(id, file_entry)
    File.join(path(id), file_entry)
  end

  def self.make_root
    FileUtils.mkdir_p(root) unless Dir.exist?(root)
  end

  def self.make_path(id)
    make_root
    FileUtils.mkdir_p(path(id)) unless Dir.exist?(path(id))
  end

  def self.make_path_entry(id, file_entry)
    make_root
    dir = path(id)
    file_entry.split(File::SEPARATOR).each do |sub_dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir = File.join(dir, sub_dir)
    end
  end
end

require_relative './webgl/cache'
require_relative './webgl/unity'
require_relative './webgl/unity_validator'
