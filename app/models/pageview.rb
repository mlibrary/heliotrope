# frozen_string_literal: true

class Pageview
  extend Legato::Model

  metrics :pageviews
  dimensions :date, :pagePath
end

class GABounceRate
  extend Legato::Model

  metrics :bounceRate
end

class GASessions
  extend Legato::Model

  metrics :sessions
end

class GAUsers
  extend Legato::Model

  metrics :users
end

class GAPages
  extend Legato::Model

  dimensions :pageTitle
  metrics :pageviews
end

class GALandingPages
  extend Legato::Model

  dimensions :landingPagePath, :pageTitle
  metrics :pageviews
end

class GAChannels
  extend Legato::Model

  dimensions :channelGrouping
  metrics :pageviews
end

class GAReferrers
  extend Legato::Model

  dimensions :fullReferrer
  metrics :pageviews
end
