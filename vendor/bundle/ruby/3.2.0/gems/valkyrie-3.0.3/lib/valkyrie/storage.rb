# frozen_string_literal: true
module Valkyrie
  # This is a namespacing module for storage adapters, which store binary content as per the DataMapper pattern
  #  https://en.wikipedia.org/wiki/Data_mapper_pattern
  #
  # @note These storage adapters do not store metadata
  #       See Valkyrie::Persistence for persisting metadata.
  #
  # @example Register storage adapters in an initializer using Valkyrie::StorageAdapter.register
  #
  #    # Store files on local disk
  #    Valkyrie::StorageAdapter.register(
  #      Valkyrie::Storage::Disk.new(base_path: '/path/to/files'),
  #      :disk
  #    )
  #
  # @example Retrieve a registered persister using Valkyrie::StorageAdapter.find
  #
  #   storage = Valkyrie.config.storage_adapter  # default
  #   storage = Valkyrie::StorageAdapter.find(:disk)  # named
  #
  # @example Save/upload a file
  #
  #   file_set = FileSet.new title: 'page 1'
  #   upload = ActionDispatch::Http::UploadedFile.new tempfile: File.new('/path/to/files/file1.tiff'), filename: 'file1.tiff', type: 'image/tiff'
  #   file = storage.upload(file: upload, resource: file_set)
  #   file_set.file_identifiers << file.id
  #   persister.save(resource: file_set)
  #
  # @see https://github.com/samvera-labs/valkyrie/wiki/Storage-&-Files
  # @see lib/valkyrie/specs/shared_specs/storage_adapter.rb
  module Storage
    require 'valkyrie/storage/disk'
    require 'valkyrie/storage/fedora'
    require 'valkyrie/storage/memory'
  end
end
