# frozen_string_literal: true
module Valkyrie
  # StorageAdapter is the primary DataMapper object for binary content persistence.
  #  Used to register and locate adapters for individual
  #  storage backends (such as fedora, disk, etc)
  class StorageAdapter
    class FileNotFound < StandardError; end
    class AdapterNotFoundError < StandardError; end
    class_attribute :storage_adapters
    self.storage_adapters = {}
    class << self
      # Add a storage adapter to the registry under the provided short name
      # @param storage_adapter [Valkyrie::StorageAdapter]
      # @param short_name [Symbol]
      # @return [void]
      def register(storage_adapter, short_name)
        storage_adapters[short_name] = storage_adapter
      end

      # @param short_name [Symbol]
      # @return [void]
      def unregister(short_name)
        storage_adapters.delete(short_name)
      end

      # Find the adapter associated with the provided short name
      # @param short_name [Symbol]
      # @return [Valkyrie::StorageAdapter]
      # @raise Valkyrie::StorageAdapter::AdapterNotFoundError when we are unable to find the named adapter
      def find(short_name)
        storage_adapters.fetch(short_name)
      rescue KeyError
        raise "Unable to find #{self} with short_name of #{short_name.inspect}. Registered adapters are #{storage_adapters.keys.inspect}"
      end

      # Search through all registered storage adapters until it finds one that
      # can handle the passed in identifier.  The call find_by on that adapter
      # with the given identifier.
      # @param id [Valkyrie::ID]
      # @return [Valkyrie::StorageAdapter::File]
      # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
      def find_by(id:)
        adapter_for(id: id).find_by(id: id)
      end

      # Search through all registered storage adapters until it finds one that
      # can handle the passed in identifier.  Then call delete on that adapter
      # with the given identifier.
      # @param id [Valkyrie::ID]
      def delete(id:)
        adapter_for(id: id).delete(id: id)
      end

      # Return the registered storage adapter which handles the given ID.
      # @param id [Valkyrie::ID]
      # @return [Valkyrie::StorageAdapter]
      def adapter_for(id:)
        handler = storage_adapters.values.find do |storage_adapter|
          storage_adapter.handles?(id: id)
        end

        raise AdapterNotFoundError, 'Unable to find a StorageAdapter' if handler.nil?
        handler
      end
    end

    class File < Dry::Struct
      attribute :id, Valkyrie::Types::Any
      attribute :io, Valkyrie::Types::Any
      delegate :size, :read, :rewind, :close, to: :io
      def stream
        io
      end

      def disk_path
        Pathname.new(io.path)
      end

      # @param digests [Array<Digest>]
      # @return [Array<Digest>]
      def checksum(digests:)
        io.rewind
        while (chunk = io.read(4096))
          digests.each { |digest| digest.update(chunk) }
        end

        digests.map(&:to_s)
      end

      # @param size [Integer]
      # @param digests [Array<Digest>]
      # @return [Boolean]
      def valid?(size: nil, digests:)
        return false if size && io.size.to_i != size.to_i
        calc_digests = checksum(digests: digests.keys.map { |alg| Digest(alg.upcase).new })
        return false unless digests.values == calc_digests

        true
      end
    end

    class StreamFile < File
      def disk_path
        Pathname.new(tmp_file.path)
      end

      private

      def tmp_file_name
        id.to_s.tr(':/', '__')
      end

      def tmp_file_path
        ::File.join(Dir.tmpdir, tmp_file_name)
      end

      def tmp_file
        @tmp_file ||= ::File.open(tmp_file_path, 'w+b') do |f|
          IO.copy_stream(io, f)
          f
        end
      end
    end
  end
end
