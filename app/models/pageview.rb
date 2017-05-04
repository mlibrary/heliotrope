# frozen_string_literal: true

class Pageview
  extend Legato::Model

  metrics :pageviews
  dimensions :date, :pagePath
end
