# frozen_string_literal: true

require "rails_autolink/helpers"

module Hyrax
  module Renderers
    class AttributeRenderer
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::TranslationHelper
      include ActionView::Helpers::TextHelper
      include ConfiguredMicrodata

      attr_reader :field, :values, :options

      # @param [Symbol] field
      # @param [Array] values
      # @param [Hash] options
      def initialize(field, values, options = {})
        @field = field
        @values = values
        @options = options
      end

      # Draw the table row for the attribute
      def render
        markup = ''
        return markup if values.blank? && !options[:include_empty]
        markup << if label.empty?
                    %(<tr><td colspan="2"><ul class='tabular list-unstyled'>)
                  else
                    %(<tr><th>#{label}</th>\n<td><ul class='tabular list-unstyled'>)
                  end
        attributes = microdata_object_attributes(field).merge(class: "attribute #{field}")

        maybe_sort_values

        Array(values).each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end

        markup << %(</ul></td></tr>)
        markup.html_safe
      end

      # Draw the dl row for the attribute
      def render_dl_row
        markup = ''

        return markup if values.blank? && !options[:include_empty]
        markup << %(<dt>#{label}</dt>\n<dd><ul class='tabular'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        Array(values).each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end
        markup << %(</ul></dd>)
        markup.html_safe
      end

      def maybe_sort_values # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        # options[:sort_by] is an array showing values' items in their intended order
        return if options[:sort_by].blank? || !values.is_a?(Array) || values.count < 1
        ordered_values = []
        options[:sort_by].each do |ordered_item|
          values.each { |unordered_item| ordered_values << ordered_item if unordered_item == ordered_item }
        end
        # there may be (but should't be) missing values (values - ordered_values), add them to the end
        @values = ordered_values + (values - ordered_values) if ordered_values.present?
      end

      # @return The human-readable label for this field.
      # @note This is a central location for determining the label of a field
      #   name. Can be overridden if more complicated logic is needed.
      def label
        translate(
          :"blacklight.search.fields.show.#{field}",
          default: [:"blacklight.search.fields.#{field}", options.fetch(:label, field.to_s.humanize)]
        )
      end

      private

        def attribute_value_to_html(value)
          if microdata_value_attributes(field).present?
            "<span#{html_attributes(microdata_value_attributes(field))}>#{li_value(value)}</span>"
          else
            li_value(value)
          end
        end

        def html_attributes(attributes)
          buffer = ""
          attributes.each do |k, v|
            buffer << " #{k}"
            buffer << %(="#{v}") if v.present?
          end
          buffer
        end

        def li_value(value)
          auto_link(ERB::Util.h(value))
        end
    end
  end
end
