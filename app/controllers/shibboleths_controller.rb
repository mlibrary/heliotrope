# frozen_string_literal: true

class ShibbolethsController < CheckpointController
  def discofeed
    flag = true
    obj_disco_feed = JSON.parse(HTTParty.get("https://heliotrope-testing.hydra.lib.umich.edu/Shibboleth.sso/DiscoFeed").body)
    if flag
      obj_filtered_disco_feed = obj_disco_feed
    else
      obj_filtered_disco_feed = []
      obj_disco_feed.each do |entry|
        obj_filtered_disco_feed << entry if entry["entityID"] == "https://shibboleth.umich.edu/idp/shibboleth"
      end
    end
    render json: obj_filtered_disco_feed
  end

  def help; end
end
