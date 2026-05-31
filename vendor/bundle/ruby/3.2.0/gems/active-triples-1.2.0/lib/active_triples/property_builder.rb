# frozen_string_literal: true
module ActiveTriples
  ##
  # A builder for property `NodeConfig`s
  #
  # @example 
  #   PropertyBuilder.build(:creator, predicate: RDF::Vocab::DC.creator)
  # 
  # @see NodeConfig
  class PropertyBuilder

    # @!attribute [r] name
    #   @return
    # @!attribute [r] options
    #   @return
    attr_reader :name, :options

    ##
    # @param name []
    # @param options []
    def initialize(name, options, &block)
      @name = name
      @options = options
    end

    ##
    # @param  name [Symbol]
    # @param  options [Hash<Symbol>]
    # @option options [RDF::URI] :predicate  
    # @option options [String, Class] :class_name
    # @option options [Boolean] :cast
    #
    # @yield yields to block configuring index behaviors
    # @yieldparam index_object [NodeConfig::IndexObject]
    #
    # @return [PropertyBuilder]
    # @raise [ArgumentError] if name is not a symbol and/or :predicate can't be
    #   coerced into a URI
    #
    # @see #build
    def self.create_builder(name, options, &block)
      raise ArgumentError, "property names must be a Symbol" unless
        name.kind_of?(Symbol)

      options[:predicate] = RDF::URI.intern(options[:predicate])
      raise ArgumentError, "must provide an RDF::URI to :predicate" unless
        options[:predicate].valid?

      new(name, options, &block)
    end

    def self.build(model, name, options, &block)
      builder = create_builder name, options, &block
      reflection = builder.build(&block)
      define_accessors model, reflection, options
      reflection
    end

    def self.define_accessors(model, reflection, options={})
      mixin = model.generated_property_methods
      name = reflection.term
      define_readers(mixin, name)
      define_id_reader(model, name) unless options[:cast] == false
      define_writers(mixin, name)
    end

    def self.define_readers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)
          get_values(:#{name}, *args)
        end
      CODE
    end

    def self.define_id_reader(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_ids(*)
          get_values(:#{name}, cast: false)
        end
      CODE
    end

    def self.define_writers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          set_value(:#{name}, value)
        end
      CODE
    end
    
    ##
    # @yield yields to block configuring index behaviors
    # @yieldparam index_object [NodeConfig::IndexObject]
    #
    # @return [NodeConfig] a new property node config
    def build(&block)
      NodeConfig.new(name,
                     options[:predicate],
                     options.except(:predicate)) do |config|
        config.with_index(&block) if block_given?
      end
    end
  end
end
