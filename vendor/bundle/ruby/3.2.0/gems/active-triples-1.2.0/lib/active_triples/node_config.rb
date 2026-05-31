# frozen_string_literal: true

module ActiveTriples
  ##
  # Configuration for properties
  class NodeConfig
    ##
    # @!attribute class_name [rw]
    #   @return [Class, String]
    # @!attribute predicate [rw]
    #   @return [RDF::URI]
    # @!attribute term [rw]
    #   @return [Symbol]
    # @!attribute type [rw]
    #   @return [Symbol]
    # @!attribute behaviors [rw]
    #   @return [Enumerator<Symbol>]
    # @!attribute cast [rw]
    #   @return [Boolean]
    attr_accessor :predicate, :term, :class_name, :type, :behaviors, :cast

    ##
    # @param  term      [Symbol]
    # @param  predicate [RDF::URI]
    # @param  opts      [Hash<Symbol, Object>]
    # @option opts      [String, Class] :class_name
    # @option opts      [String, Class] :class_name
    #
    # @yield yields self to the block
    # @yieldparam config [NodeConfig] self
    def initialize(term, predicate, opts={})
      self.term = term
      self.predicate = predicate
      self.class_name = opts.delete(:class_name) { nil }
      self.cast = opts.delete(:cast) { true }
      @opts = opts
      yield(self) if block_given?
    end

    ##
    # @param value [#to_sym]
    # @return [Object] the attribute or option represented by the symbol
    def [](value)
      value = value.to_sym
      self.respond_to?(value) ? self.public_send(value) : @opts[value]
    end

    def class_name
      return nil if @class_name.nil?
      raise "class_name for #{term} is a #{@class_name.class}; must be a class" unless @class_name.kind_of? Class or @class_name.kind_of? String
      if @class_name.kind_of?(String)
        begin
          new_class = @class_name.constantize
          @class_name = new_class
        rescue NameError
        end
      end
      @class_name
    end

    ##
    # @yield yields an index configuration object
    # @yieldparam index [NodeConfig::IndexObject]
    def with_index(&block)
      # needed for solrizer integration
      iobj = IndexObject.new
      yield iobj
      self.type = iobj.data_type
      self.behaviors = iobj.behaviors
    end

    private

    ##
    # @deprecated Use `nil` instead.
    def default_class_name
        warn 'DEPRECATION: `ActiveTriples::NodeConfig#default_class_name` ' \
             'will be removed in 1.0. Use `nil`.'
      nil
    end

    # this enables a cleaner API for solr integration
    class IndexObject
      ##
      # @!attribute data_type [rw]
      #   @return [Symbol]
      # @!attribute behaviors [rw]
      #   @return [Enumerator<Symbol>]
      attr_accessor :data_type, :behaviors

      def initialize
        @behaviors = []
        @data_type = :string
      end

      ##
      # @param [Array<Symbol>] *args Behaviors for this index object
      #
      # @return [Array<Symbol>]
      def as(*args)
        @behaviors = args
      end

      ##
      # @param sym [Symbol]
      def type(sym)
        @data_type = sym
      end

      ##
      # @deprecated Omit calls to this method; it has always been a no-op.
      #
      # @return [Symbol] :noop
      def defaults # no-op
        warn 'DEPRECATION: `ActiveTriples::NodeConfig::IndexObject#defaults` ' \
             'will be removed in 1.0. If you are doing `index.defaults` in a ' \
             'property config block, you can simply omit the call.'
        :noop
      end
    end
  end
end
