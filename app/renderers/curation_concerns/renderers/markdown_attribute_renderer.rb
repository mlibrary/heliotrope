require "rails_autolink/helpers"

module CurationConcerns
  module Renderers
    class MarkdownAttributeRenderer < AttributeRenderer
      def render
        markup = ''

        return markup if !values.present? && !options[:include_empty]
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular list-unstyled'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute #{field}")
        Array(values).each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end
        markup << %(</ul></td></tr>)
        markup = MarkdownService.markdown(markup)
        markup.html_safe
      end
    end
  end
end
