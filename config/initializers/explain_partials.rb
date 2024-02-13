# frozen_string_literal: true

# Start the app with EXPLAIN_PARTIALS=true to show locations of view partials
if Rails.env.development? && ENV['EXPLAIN_PARTIALS']
  module ExplainPartials
    def initialize(body, layout, template)
      # we really only want this to run for HTML templates, i.e. `ActionView::Template::HTML`
      # `render :plain` stuff like RIIIF's JSON endpoint is `ActionView::Template::Text` and won't have the necessary...
      # methods used below to identify its path. Also the added HTML comments will break JSON parsing anyways.
      @body = if template.class.method_defined?(:short_identifier)
                if template.class.method_defined?(:locals) && template.locals.present?
                  "\n<!-- START PARTIAL #{template.short_identifier} locals=#{template.locals.inspect} -->\n" \
                  "#{body}\n" \
                  "<!-- END PARTIAL #{template.short_identifier} locals=#{template.locals.inspect} -->\n".html_safe # rubocop:disable Rails/OutputSafety
                else
                  "\n<!-- START PARTIAL #{template.short_identifier} -->\n" \
                  "#{body}\n" \
                  "<!-- END PARTIAL #{template.short_identifier} -->\n".html_safe # rubocop:disable Rails/OutputSafety
                end
              else
                # do nothing here, it's `render :plain` and probably JSON or something!
                body
              end
      @layout = layout
      @template = template
    end
  end

  ActionView::AbstractRenderer::RenderedTemplate.prepend(ExplainPartials)
end
