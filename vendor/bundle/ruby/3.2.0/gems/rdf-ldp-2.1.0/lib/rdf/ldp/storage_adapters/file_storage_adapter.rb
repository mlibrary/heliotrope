module RDF::LDP
  class NonRDFSource < Resource
    ##
    # StorageAdapters bundle the logic for mapping a `NonRDFSource` to a
    # specific IO stream. Implementations must conform to a minimal interface:
    #
    #  - `#initailize` must accept a `resource` parameter. The input should be
    #     a `NonRDFSource` (LDP-NR).
    #  - `#io` must yield and return a IO object in binary mode that represents
    #    the current state of the LDP-NR.
    #    - If a block is passed to `#io`, the implementation MUST allow return a
    #      writable IO object and that anything written to the stream while
    #      yielding is synced with the source in a thread-safe manner.
    #    - Clients not passing a block to `#io` SHOULD call `#close` on the
    #      object after reading it.
    #    - If the `#io` object responds to `#to_path` it MUST give the location
    #      of a file whose contents are identical the IO object's. This supports
    #      Rack's response body interface.
    #  - `#delete` remove the contents from the corresponding storage. This MAY
    #      be a no-op if is undesirable or impossible to delete the contents
    #      from the storage medium.
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body
    #   for details about `#to_path` in Rack response bodies.
    #
    # @example reading from a `StorageAdapter`
    #   storage = StorageAdapter.new(an_nr_source)
    #   storage.io.read # => [string contents of `an_nr_source`]
    #
    # @example writing to a `StorageAdapter`
    #   storage = StorageAdapter.new(an_nr_source)
    #   storage.io { |io| io.write('moomin') }
    #
    # Beyond this interface, implementations are permitted to behave as desired.
    # They may, for instance, reject undesirable content or alter the graph (or
    # metagraph) of the resource. They should throw appropriate `RDF::LDP`
    # errors when failing to allow the middleware to handle response codes and
    # messages.
    #
    # The base storage adapter class provides a simple File storage
    # implementation.
    #
    # @todo check thread saftey on write for base implementation
    class FileStorageAdapter
      STORAGE_PATH = '.storage'.freeze

      ##
      # Initializes the storage adapter.
      #
      # @param [NonRDFSource] resource
      def initialize(resource)
        @resource = resource
      end

      ##
      # Gives an IO object which represents the current state of @resource.
      # Opens the file for read-write (mode: r+), if it already exists;
      # otherwise, creates the file and opens it for read-write (mode: w+).
      #
      # @yield [IO] yields a read-writable object conforming to the Ruby IO
      #   interface for storage. The IO object will be closed when the block
      #   ends.
      #
      # @return [IO] an object conforming to the Ruby IO interface
      def io(&block)
        FileUtils.mkdir_p(path_dir) unless Dir.exist?(path_dir)
        FileUtils.touch(path) unless file_exists?

        File.open(path, 'r+b', &block)
      end

      ##
      # @return [Boolean] 1 if the file has been deleted, otherwise false
      def delete
        return false unless File.exist?(path)
        File.delete(path)
      end

      private

      ##
      # @return [Boolean]
      def file_exists?
        File.exist?(path)
      end

      ##
      # Build the path to the file on disk.
      # @return [String]
      def path
        File.join(STORAGE_PATH, @resource.subject_uri.path)
      end

      ##
      # Build the path to the file's directory on disk
      # @return [String]
      def path_dir
        File.split(path).first
      end
    end
  end
end
