module Hyrax
  module Renderers
    class FileSizeAttributeRenderer < AttributeRenderer
      private
        def attribute_value_to_html(value)
          ActiveSupport::NumberHelper.number_to_human_size(value)
        end
    end
  end
end
