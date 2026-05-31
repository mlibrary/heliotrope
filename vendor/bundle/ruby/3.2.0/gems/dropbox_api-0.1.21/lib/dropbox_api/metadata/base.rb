# frozen_string_literal: true
module DropboxApi::Metadata
  class Base
    class << self
      attr_reader :fields

      def field(name, type, *options)
        @fields ||= {}
        @fields[name] = DropboxApi::Metadata::Field.new(type, options)

        attr_reader name
      end
    end

    # Takes in a hash containing all the attributes required to initialize the
    # object.
    #
    # Each hash entry should have a key which identifies a field and its value,
    # so a valid call would be something like this:
    #
    #     DropboxApi::Metadata::File.new({
    #       "name" => "a.jpg",
    #       "path_lower" => "/a.jpg",
    #       "path_display" => "/a.jpg",
    #       "id" => "id:evvfE6q6cK0AAAAAAAAB2w",
    #       "client_modified" => "2016-10-19T17:17:34Z",
    #       "server_modified" => "2016-10-19T17:17:34Z",
    #       "rev" => "28924061bdd",
    #       "size" => 396317
    #     })
    #
    # @raise [ArgumentError] If a required attribute is missing.
    # @param metadata [Hash]
    def initialize(metadata)
      self.class.fields.keys.each do |field_name|
        self[field_name] = metadata[field_name.to_s]
      end
    end

    def to_hash
      Hash[self.class.fields.keys.map do |field_name|
        [field_name.to_s, serialized_field(field_name)]
      end.select { |k, v| !v.nil? }]
    end

    def serialized_field(field_name)
      value = send field_name
      case value
      when Time
        value.utc.strftime('%FT%TZ')
      when DropboxApi::Metadata::Base
        value.to_hash
      else
        value
      end
    end

    private

    def []=(name, value)
      instance_variable_set "@#{name}", self.class.fields[name].cast(value)
    rescue ArgumentError
      raise ArgumentError, "Invalid value for `#{name}`: #{value.inspect}."
    end
  end
end
