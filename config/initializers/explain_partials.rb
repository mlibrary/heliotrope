# frozen_string_literal: true

# Start the app with EXPLAIN_PARTIALS=true to show locations of view partials
if Rails.env.development? && ENV['EXPLAIN_PARTIALS']
  module ExplainPartials
    def initialize(body, layout, template)
      @body = if template.locals.present?
                "\n<!-- START PARTIAL #{template.short_identifier} locals=#{template.locals.inspect} -->\n" \
                "#{body}\n" \
                "<!-- END PARTIAL #{template.short_identifier} locals=#{template.locals.inspect} -->\n".html_safe # rubocop:disable Rails/OutputSafety
              else
                "\n<!-- START PARTIAL #{template.short_identifier} -->\n" \
                "#{body}\n" \
                "<!-- END PARTIAL #{template.short_identifier} -->\n".html_safe # rubocop:disable Rails/OutputSafety
              end

      @layout = layout
      @template = template
    end
  end

  ActionView::AbstractRenderer::RenderedTemplate.prepend(ExplainPartials)
end
