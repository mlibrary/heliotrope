require "rails_autolink/helpers"

module CurationConcerns
  module Renderers
    class MarkdownAttributeRenderer < AttributeRenderer
      def render
        markup = ''
        return markup if !values.present? && !options[:include_empty]
        markup_values = []
        Array(values).each do |value|
          markup_values << if options[:newlines_only]
                             # need to manually escape the value here as it's bypassing the service
                             ERB::Util.h(value).gsub(/(?:\n\r?|\r\n?)/, '<br>')
                           else
                             MarkdownService.markdown(value)
                           end
        end

        markup << if label.empty?
                    %(<tr><td colspan="2"><ul class='tabular list-unstyled'>)
                  else
                    %(<tr><th>#{label}</th>\n<td><ul class='tabular list-unstyled'>)
                  end
        attributes = microdata_object_attributes(field).merge(class: "attribute #{field}")
        markup_values.each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value)}</li>"
        end
        markup << %(</ul></td></tr>)
        markup.html_safe
      end

      # override to not HTML escape or autolink here, leave it to Redcarpet
      def li_value(value)
        # CC's usage:
        # auto_link(ERB::Util.h(value))
        value
      end
    end
  end
end
