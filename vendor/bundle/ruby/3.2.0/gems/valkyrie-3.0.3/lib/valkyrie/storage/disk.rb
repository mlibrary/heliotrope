# frozen_string_literal: true
module Valkyrie::Storage
  # Implements the DataMapper Pattern to store binary data on disk
  class Disk
    attr_reader :base_path, :path_generator, :file_mover
    def initialize(base_path:, path_generator: BucketedStorage, file_mover: FileUtils.method(:mv))
      @base_path = Pathname.new(base_path.to_s)
      @path_generator = path_generator.new(base_path: base_path)
      @file_mover = file_mover
    end

    # @param file [IO]
    # @param original_filename [String]
    # @param resource [Valkyrie::Resource]
    # @param _extra_arguments [Hash] additional arguments which may be passed to other adapters
    # @return [Valkyrie::StorageAdapter::File]
    def upload(file:, original_filename:, resource: nil, **_extra_arguments)
      new_path = path_generator.generate(resource: resource, file: file, original_filename: original_filename)
      FileUtils.mkdir_p(new_path.parent)
      file_mover.call(file.path, new_path)
      find_by(id: Valkyrie::ID.new("disk://#{new_path}"))
    end

    # @param id [Valkyrie::ID]
    # @return [Boolean] true if this adapter can handle this type of identifer
    def handles?(id:)
      id.to_s.start_with?("disk://#{base_path}")
    end

    def file_path(id)
      id.to_s.gsub(/^disk:\/\//, '')
    end

    # Return the file associated with the given identifier
    # @param id [Valkyrie::ID]
    # @return [Valkyrie::StorageAdapter::File]
    # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
    def find_by(id:)
      Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new(id.to_s), io: LazyFile.open(file_path(id), 'rb'))
    rescue Errno::ENOENT
      raise Valkyrie::StorageAdapter::FileNotFound
    end

    ## LazyFile takes File.open parameters but doesn't leave a file handle open on
    # instantiation. This way StorageAdapter#find_by doesn't open a handle
    # silently and never clean up after itself.
    class LazyFile
      def self.open(path, mode)
        # Open the file regularly and close it, so it can error if it doesn't
        # exist.
        File.open(path, mode).close
        new(path, mode)
      end

      delegate(*(File.instance_methods - Object.instance_methods), to: :_inner_file)

      def initialize(path, mode)
        @__path = path
        @__mode = mode
      end

      def _inner_file
        @_inner_file ||= File.open(@__path, @__mode)
      end
    end

    # Delete the file on disk associated with the given identifier.
    # @param id [Valkyrie::ID]
    def delete(id:)
      path = file_path(id)
      FileUtils.rm_rf(path) if File.exist?(path)
    end

    class BucketedStorage
      attr_reader :base_path
      def initialize(base_path:)
        @base_path = base_path
      end

      def generate(resource:, file:, original_filename:)
        raise ArgumentError, "original_filename must be provided" unless original_filename
        Pathname.new(base_path).join(*bucketed_path(resource.id)).join(original_filename)
      end

      def bucketed_path(id)
        cleaned_id = id.to_s.delete("-")
        cleaned_id[0..5].chars.each_slice(2).map(&:join) + [cleaned_id]
      end
    end
  end
end
