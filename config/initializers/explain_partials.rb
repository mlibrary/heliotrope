# frozen_string_literal: true

# Start the app with EXPLAIN_PARTIALS=true to show locations of view partials
if Rails.env.development? && ENV['EXPLAIN_PARTIALS']
  module ExplainPartials
    def render(*args)
      rendered = super(*args).to_s
      # Note: We haven't figured out how to get a path when @template is nil.
      start_explanation = "\n<!-- START PARTIAL #{@template.inspect} -->\n"
      end_explanation = "\n<!-- END PARTIAL #{@template.inspect} -->\n"
      start_explanation.html_safe + rendered + end_explanation.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  ActionView::PartialRenderer.prepend(ExplainPartials)
end
