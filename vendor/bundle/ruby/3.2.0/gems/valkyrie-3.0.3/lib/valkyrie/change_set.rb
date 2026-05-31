# frozen_string_literal: true
require 'reform/form/coercion'
require 'reform/form/orm'
require 'reform/form/active_model'
require 'reform/form/active_model/validations'
require 'reform/form/active_model/model_reflections'
require 'reform/form/active_model/form_builder_methods'
module Valkyrie
  ##
  # Standard change set object for Valkyrie.
  # ChangeSets are a way to group together properties that should be applied to
  # an underlying resource. They are often used for powering HTML Forms or
  # storing virtual attributes for special synchronization with a resource.
  # @example Define a change set
  #   class BookChangeSet < Valkyrie::ChangeSet
  #     self.fields = [:title, :author]
  #     validates :title, presence: true
  #     property :title, multiple: false, required: true
  #   end
  class ChangeSet < Reform::Form
    include Reform::Form::ORM
    include Reform::Form::ModelReflections
    include Reform::Form::ActiveModel
    include Reform::Form::ActiveModel::Validations
    include Reform::Form::ActiveModel::FormBuilderMethods
    feature Coercion
    class_attribute :fields
    self.fields = []

    property :append_id, virtual: true

    # Set ID of record this one should be appended to.
    # We use append_id to add a member/child onto an existing list of members.
    # @param append_id [Valkyrie::ID]
    def append_id=(append_id)
      super(Valkyrie::ID.new(append_id))
    end

    # Returns whether or not a given field has multiple values.
    # Multiple values are useful for fields like creator, author, title, etc.
    # where there may be more than one value for a field that is stored and returned in the UI
    # @param field_name [Symbol]
    # @return [Boolean]
    def multiple?(field_name)
      field(field_name)[:multiple] != false
    end

    # Returns whether or not a given field is required.
    # Useful for distinguishing required fields in a form and for validation
    # @param field_name [Symbol]
    # @return [Boolean]
    def required?(field_name)
      field(field_name)[:required] == true
    end

    # Quick setter for fields that should be in a changeset. Defaults to multiple,
    # not required, with an empty array default.
    # @param fields [Array<Symbol>]
    def self.fields=(fields)
      singleton_class.class_eval do
        remove_possible_method(:fields)
        define_method(:fields) { fields }
      end

      fields.each do |field|
        property field, default: []
      end
      fields
    end

    # Override reflect_on_association so SimpleForm can work.
    def self.reflect_on_association(*_args); end

    # Returns value for a given property.
    # @param key [Symbol]
    def [](key)
      send(key) if respond_to?(key)
    end

    [:internal_resource, :created_at, :updated_at, :model_name, :optimistic_locking_enabled?, :attributes].each do |method_name|
      define_method(method_name) do |*args|
        resource.public_send(method_name, *args)
      end
    end

    # Prepopulates all fields with defaults defined in the changeset. This is an
    # override of Reform::Form's method to allow for single-valued fields to
    # prepopulate appropriately.
    def prepopulate!(_options = {})
      self.class.definitions.select { |_field, definition| definition[:multiple] == false }.each_key do |field|
        value = Array.wrap(send(field.to_s)).first
        send("#{field}=", value)
      end
      super
      self
    end

    def resource
      model
    end

    def valid?
      errors.clear
      super
    end

    private

    def field(field_name)
      self.class.definitions.fetch(field_name.to_s)
    end
  end
end
