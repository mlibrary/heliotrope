# frozen_string_literal: true
module ActiveTriples
  ##
  # A value object to encapsulate what a Property is. Instantiate with a hash of
  # options.
  #
  # @example configuring a property in a schema
  #   title_prop = ActiveTriples::Property.new(name:     :title,
  #                                            predicate: RDF::Vocab::DC.title)
  class Property
    ##
    # @param options [Hash] Options for the property
    # @option options [RDF::URI] :name
    # @option options [Boolean] :cast
    # @option options [String, Class] :class_name
    # @option options [RDF::URI] :predicate
    def initialize(options = {}, &block)
      self.name       = options.fetch(:name)
      self.attributes = options.except(:name)
      self.config     = block 
    end

    ##
    # @!attribute [r] name
    #   @return [Symbol]
    # @!attribute [r] config
    #   @return [Proc]
    attr_reader :name, :config

    ##
    # @return [Boolean]
    def cast
      attributes.fetch(:cast, false)
    end

    ##
    # @return [Class]
    def class_name
      attributes[:class_name]
    end

    ##
    # @return [RDF::Vocabulary::Term]
    def predicate
      attributes[:predicate]
    end

    private

    ##
    # @!attribute [w] name
    #   @return [Symbol]
    # @!attribute [w] config
    #   @return [Proc]
    # @!attribute [rw] attributes
    #   @return [Hash<Symbol, Object>]
    attr_writer   :name, :config
    attr_accessor :attributes

    alias_method :to_h, :attributes

    ##
    # Returns the property's configuration values. Will not return #name, which 
    # is meant to only be accessible via the accessor.
    # 
    # @return [Hash] Configuration values for this property.
    public :to_h
  end
end
