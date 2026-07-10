# frozen_string_literal: true

class MultiValueTextareaInput < MultiValueInput
  def build_field(value, index)
    options = input_html_options.dup
    options[:value] = value

    if value.respond_to?(:rdf_label)
      options[:value] = value.rdf_label.first
    end

    options[:name] = "#{object_name}[#{attribute_name}][]"
    options[:id] = "#{object_name}_#{attribute_name}_#{index}"
    options[:rows] ||= 3
    options[:class] ||= []
    options[:class] += ['string', 'multi_value', 'optional', 'form-control',
                        "monograph_#{attribute_name}", 'form-control', 'multi-text-field']
    options[:aria_labelledby] ||= "#{options[:id]}_label"

    @builder.text_area(attribute_name, options)
  end

  def input_type
    'multi_value'
  end
end
