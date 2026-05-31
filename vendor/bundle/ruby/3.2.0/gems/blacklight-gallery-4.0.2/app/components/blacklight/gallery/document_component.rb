# frozen_string_literal: true

module Blacklight
  module Gallery
    class DocumentComponent < Blacklight::DocumentComponent
      def before_render
        thumbnail(image_options: { class: 'img-thumbnail' }) unless thumbnail.present?
        super
      end

      def render_document_class(*args)
        @view_context.render_document_class(*args)
      end
    end
  end
end
