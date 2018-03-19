# frozen_string_literal: true

module EPub
  #
  # Logger
  #
  require 'logger'
  # mattr_accessor :logger
  @logger = Logger.new(STDOUT)

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  #
  # File System Cache Paths
  #
  # mattr_accessor :root
  @root = './tmp/epubs'

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

  #
  # Configure
  #
  @configured = false

  # spec helper
  def self.reset_configured_flag
    @configured = false
  end

  def self.configured?
    @configured
  end

  def self.configure
    @configured = true
    yield self
  end
end

#
# Require Relative
#
require_relative './e_pub/bridge_to_webgl'
require_relative './e_pub/cache'
require_relative './e_pub/cfi'
require_relative './e_pub/chapter'
require_relative './e_pub/chapter_null_object'
require_relative './e_pub/chapter_presenter'
require_relative './e_pub/paragraph'
require_relative './e_pub/paragraph_null_object'
require_relative './e_pub/paragraph_presenter'
require_relative './e_pub/presenter'
require_relative './e_pub/publication'
require_relative './e_pub/publication_null_object'
require_relative './e_pub/publication_presenter'
require_relative './e_pub/search'
require_relative './e_pub/snippet'
require_relative './e_pub/sql_lite'
require_relative './e_pub/sql_lite_null_object'
require_relative './e_pub/validator'
