module HydraEditor
  module Form
    extend ActiveSupport::Autoload
    autoload :Permissions
    extend ActiveSupport::Concern

    include Hydra::Presenter
    included do
      class_attribute :required_fields
      self.required_fields = []
      delegate :errors, to: :model
    end

    def initialize(model)
      super
      initialize_fields
    end

    def required?(key)
      required_fields.include?(key)
    end

    def [](key)
      @attributes[key.to_s]
    end

    def []=(key, value)
      @attributes[key.to_s] = value
    end

    class Validator < ActiveModel::Validations::PresenceValidator
      def self.kind
        :presence
      end
    end

    module ClassMethods
      def validators_on(*attributes)
        attributes.flat_map do |attribute|
          if required_fields.include?(attribute)
            [Validator.new(attributes: [attribute])]
          else
            []
          end
        end
      end

      def multiple?(field)
        field_metadata_service.multiple?(model_class, field)
      end

      # Return a hash of all the parameters from the form as a hash.
      # This is typically used by the controller as the main read interface to the form.
      # This hash can then be used to create or update an object in the data store.
      # example:
      #   ImageForm.model_attributes(params[:image])
      #   # => { title: 'My new image' }
      def model_attributes(form_params)
        sanitize_params(form_params).tap do |clean_params|
          terms.each do |key|
            if clean_params[key]
              if multiple?(key)
                clean_params[key].delete('')
              elsif clean_params[key] == ''
                clean_params[key] = nil
              end
            end
          end
        end
      end

      def sanitize_params(form_params)
        form_params.permit(*permitted_params)
      end

      def permitted_params
        @permitted ||= build_permitted_params
      end

      def build_permitted_params
        permitted = []
        terms.each do |term|
          if multiple?(term)
            permitted << { term => [] }
          else
            permitted << term
          end
        end
        permitted
      end
    end

    protected

      def initialize_fields
        # we're making a local copy of the attributes that we can modify.
        @attributes = model.attributes
        terms.select { |key| self[key].blank? }.each { |key| initialize_field(key) }
      end

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      def initialize_field(key)
        # if value is empty, we create an one element array to loop over for output
        if multiple?(key)
          self[key] = ['']
        else
          self[key] = ''
        end
      end
  end
end
