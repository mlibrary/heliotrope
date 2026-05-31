module BlacklightOaiProvider
  class Set
    class << self
      # The controller, used to construct solr queries
      attr_accessor :controller

      # Solr field configuration for each set
      # Fields must be indexed
      attr_accessor :fields

      # Return an array of all SetSpecs, or nil if sets are not supported.
      # Objects returned must be of a class that inherits from
      # BlacklightOaiProvider::SetSpecs.
      def all
        raise NotImplementedError
      end

      # Return a Solr filter query given a set spec. Spec will be a string in
      # label:value format.
      def from_spec(spec)
        raise NotImplementedError
      end

      # Returns array of sets for a record, or empty array if none are available.
      # Objects returned must be of a class that inherits from
      # BlacklightOaiProvider::SetSpecs.
      def sets_for(record)
        raise NotImplementedError
      end
    end

    # OAI Set properties
    attr_accessor :label, :value, :description

    # Build a set object with, at minimum, a set spec string
    def initialize(spec)
      @label, @value = spec.split(':', 2)
      raise OAI::ArgumentException if [@label, @value].any?(&:blank?)
    end

    def name
      raise NotImplementedError
    end

    def spec
      raise NotImplementedError
    end
  end
end
