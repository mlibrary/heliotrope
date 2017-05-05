# frozen_string_literal: true

module GalleryHelper
  def render_gallery_collection(documents, partial)
    index = -1
    documents.map do |object|
      index += 1
      logger.debug "Looking for gallery document wrapper #{partial}"
      template = lookup_context.find_all(partial, lookup_context.prefixes, true, %i[document document_counter], {}).first
      template&.render(self, document: object, document_counter: index)
    end.join.html_safe
  end
end
