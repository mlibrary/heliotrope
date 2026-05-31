module HydraEditor
  class FieldMetadataService
    # If the field is a reflection, delegate to the reflection.
    # If the field is a property, delegate to the property.
    # Otherwise return false
    def self.multiple?(model_class, field)
      if reflection = model_class.reflect_on_association(field)
        reflection.collection?
      elsif model_class.attribute_names.include?(field.to_s)
        model_class.multiple?(field)
      else
        false
      end
    end
  end
end
