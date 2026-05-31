# frozen_string_literal: true

module Blacklight
  module Gallery
    class SlideshowComponent < Blacklight::DocumentComponent
      def count
        @document.response&.total
      end

      def render_document_class(*args)
        @view_context.render_document_class(*args)
      end

      def presenter
        @presenter ||= @view_context.document_presenter(@document)
      end

      def slideshow_tag(image_options = { alt: '' })
        if view_config.slideshow_method
          method_name = view_config.slideshow_method
          @view_context.send(method_name, @document, image_options)
        elsif view_config.slideshow_field
          return if slideshow_image_url.blank?
          image = image_tag slideshow_image_url, image_options
          helpers.link_to_document(@document, image)
        elsif presenter.thumbnail.exists?
          presenter.thumbnail.thumbnail_tag(image_options)
        end
      end

      def slideshow_image_url
        @document.first(view_config.slideshow_field) if @document.has? view_config.slideshow_field
      end

      def view_config
        presenter.thumbnail.view_config
      end
    end
  end
end
