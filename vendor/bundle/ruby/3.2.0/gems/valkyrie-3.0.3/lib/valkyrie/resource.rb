# frozen_string_literal: true
module Valkyrie
  ##
  # The base resource class for all Valkyrie metadata objects.
  # @example Define a resource
  #   class Book < Valkyrie::Resource
  #     attribute :member_ids, Valkyrie::Types::Array
  #     attribute :author
  #   end
  #
  # @see https://github.com/samvera-labs/valkyrie/wiki/Persistence Resources are persisted by metadata persisters
  # @see https://github.com/samvera-labs/valkyrie/wiki/Queries Resources are retrieved by query adapters
  # @see https://github.com/samvera-labs/valkyrie/wiki/ChangeSets-and-Dirty-Tracking Validation and change tracking is provided by change sets
  #
  # @see lib/valkyrie/specs/shared_specs/resource.rb
  # rubocop:disable Metrics/ClassLength
  class Resource < Dry::Struct
    # Allows a Valkyrie::Resource to be instantiated without providing every
    # available key, and makes sure the defaults are set up if no value is
    # given.
    def self.allow_nonexistent_keys
      transform_types(&:omittable)
    end

    # Overridden to provide default attributes.
    # @note The current theory is that we should use this sparingly.
    def self.inherited(subclass)
      super(subclass)
      subclass.allow_nonexistent_keys
      subclass.attribute :id, Valkyrie::Types::ID.optional, internal: true
      subclass.attribute :internal_resource, Valkyrie::Types::Any.default(subclass.to_s.freeze), internal: true
      subclass.attribute :created_at, Valkyrie::Types::DateTime.optional, internal: true
      subclass.attribute :updated_at, Valkyrie::Types::DateTime.optional, internal: true
      subclass.attribute :new_record, Types::Bool.default(true), internal: true
    end

    # @return [Array<Symbol>] Array of fields defined for this class.
    def self.fields
      attribute_names.without(:new_record)
    end

    # Define an attribute. Attributes are used to describe resources.
    # @param name [Symbol]
    # @param type [Dry::Types::Type]
    # @note Overridden from {Dry::Struct} to make the default type
    #   {Valkyrie::Types::Set}
    def self.attribute(name, type = Valkyrie::Types::Set.optional, internal: false)
      raise ReservedAttributeError, "#{name} is a reserved attribute and defined by Valkyrie::Resource, do not redefine it." if reserved_attributes.include?(name.to_sym) &&
                                                                                                                                attribute_names.include?(name.to_sym) &&
                                                                                                                                !internal

      super(name, type)
    end

    # @param [Hash{Symbol => Dry::Types::Type}] new_schema
    # @return [Dry::Struct]
    # @raise [RepeatedAttributeError] when trying to define attribute with the
    #   same name as previously defined one
    # @raise [ReservedAttributeError] when trying to define an attribute
    #   reserved by Valkyrie
    # @see #attribute
    # @note extends {Dry::Struct} by adding `#attr=` style setters
    def self.attributes(new_schema)
      new_schema[:member_ids] = new_schema[:member_ids].meta(ordered: true) if
        new_schema.key?(:member_ids)

      super

      new_schema.each_key do |key|
        key = key.to_s.chomp('?')
        next if instance_methods.include?("#{key}=".to_sym)

        class_eval(<<-RUBY)
          def #{key}=(value)
            set_value("#{key}".to_sym, value)
          end
        RUBY
      end

      self
    end

    def self.reserved_attributes
      [:id, :internal_resource, :created_at, :updated_at, :new_record]
    end

    # @return [ActiveModel::Name]
    # @note Added for ActiveModel compatibility.
    def self.model_name
      @model_name ||= ::ActiveModel::Name.new(self)
    end

    delegate :model_name, to: :class

    def self.human_readable_type
      @_human_readable_type ||= name.demodulize.titleize
    end

    def self.human_readable_type=(val)
      @_human_readable_type = val
    end

    def self.enable_optimistic_locking
      attribute(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK, Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken))
    end

    def self.optimistic_locking_enabled?
      schema.key?(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK)
    end

    def optimistic_locking_enabled?
      self.class.optimistic_locking_enabled?
    end

    def clear_optimistic_lock_token!
      send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", []) if optimistic_locking_enabled?
    end

    def attributes
      Hash[self.class.attribute_names.map { |x| [x, nil] }].merge(super).freeze
    end

    def __attributes__
      Hash[@attributes].freeze
    end

    def dup
      new({})
    end

    # @param name [Symbol] Attribute name
    # @return [Boolean]
    def has_attribute?(name)
      respond_to?(name)
    end

    # @param name [Symbol]
    # @return [Symbol]
    # @note Added for ActiveModel compatibility.
    def column_for_attribute(name)
      name
    end

    # @return [Boolean]
    def persisted?
      new_record == false
    end

    def to_key
      [id]
    end

    def to_param
      to_key.map(&:to_s).join('-')
    end

    # @note Added for ActiveModel compatibility
    def to_model
      self
    end

    # @return [String]
    def to_s
      "#{self.class}: #{id}"
    end

    ##
    # Provide a human readable name for the resource
    # @return [String]
    def human_readable_type
      self.class.human_readable_type
    end

    ##
    # Return an attribute's value.
    # @param name [#to_sym] the name of the attribute to read
    def [](name)
      super(name.to_sym)
    rescue Dry::Struct::MissingAttributeError
      nil
    end

    ##
    # Set an attribute's value.
    # @param key [#to_sym] the name of the attribute to set
    # @param value [] the value to set key to.
    def set_value(key, value)
      @attributes[key.to_sym] = self.class.schema.key(key.to_sym).type.call(value)
    end

    # Returns if an attribute is set as ordered.
    def ordered_attribute?(key)
      self.class.schema.key(key.to_sym).type.meta.try(:[], :ordered)
    end

    class ReservedAttributeError < StandardError; end
  end
  # rubocop:enable Metrics/ClassLength
end
