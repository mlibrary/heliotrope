class Pageview
  extend Legato::Model

  metrics :pageviews
  dimensions :date, :pagePath
end
