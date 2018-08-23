# frozen_string_literal: true

# default spec helper
require 'spec_helper'

require 'zip'

# RSpec::Mocks::MockExpectationError: An expectation of `:info` was set on `nil`.
# To allow expectations on `nil` and suppress this message,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `true`.
# To disallow expectations on `nil`,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `false`
RSpec::Mocks.configuration.allow_message_expectations_on_nil = false

# ActiveSupport
require 'active_support'
# present?, blank?, and other stuff...
require 'active_support/core_ext'
# autoload
require 'active_support/dependencies'
# lib
ActiveSupport::Dependencies.autoload_paths << File.expand_path('../../lib', __dir__)

# Use this setup block to configure all options available in EPub.
EPub.configure do |config|
  # config.logger = Rails.logger
end

# Unpacking helpers for epubs and webgls
# In Rails this is handled by the UnpackJob
# But since we're not including Rails...
module UnpackHelper
  def self.noid_to_root_path(noid, kind)
    "./tmp/rspec_derivatives/" + noid.split('').each_slice(2).map(&:join).join('/') + "-" + kind
  end

  def self.unpack_epub(id, root_path, file)
    Zip::File.open(file) do |zip_file|
      zip_file.each do |entry|
        make_path_entry(root_path, entry.name)
        entry.extract(File.join(root_path, entry.name))
      end
    end
  rescue Zip::Error
    raise "EPUB #{id} is corrupt."
  end

  def self.unpack_webgl(id, root_path, file)
    Zip::File.open(file) do |zip_file|
      zip_file.each do |entry|
        # We don't want to include the root directory, it could be named anything.
        parts = entry.name.split(File::SEPARATOR)
        without_parent = parts.slice(1, parts.length).join(File::SEPARATOR)
        make_path_entry(root_path, without_parent)
        entry.extract(File.join(root_path, without_parent))
      end
    end
  rescue Zip::Error
    raise "Webgl #{id} is corrupt."
  end

  def self.make_path_entry(root_path, file_entry)
    FileUtils.mkdir_p(root_path) unless Dir.exist?(root_path)
    dir = root_path
    file_entry.split(File::SEPARATOR).each do |sub_dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir = File.join(dir, sub_dir)
    end
  end

  def self.create_search_index(root_path)
    sql_lite = EPub::SqlLite.from_directory(root_path)
    sql_lite.create_table
    sql_lite.load_chapters
  end
end

RSpec.configure do |config|
  config.include UnpackHelper
end
