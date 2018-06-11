# frozen_string_literal: true

class ShibbolethsController < CheckpointController
  def discofeed
    json_disco_feed = <<~eos
      [
        {
         "entityID": "https://shibboleth.umich.edu/idp/shibboleth",
         "DisplayNames": [
          {
          "value": "University of Michigan",
          "lang": "en"
          }
         ],
         "Descriptions": [
          {
          "value": "The University of Michigan",
          "lang": "en"
          }
         ],
         "InformationURLs": [
          {
          "value": "http://www.umich.edu/",
          "lang": "en"
          }
         ],
         "PrivacyStatementURLs": [
          {
          "value": "http://documentation.its.umich.edu/node/262/",
          "lang": "en"
          }
         ],
         "Logos": [
          {
          "value": "https://shibboleth.umich.edu/images/StackedBlockM-InC.png",
          "height": "150",
          "width": "300",
          "lang": "en"
          }
         ]
        },
        {
         "entityID": "https://sso.mtu.edu/idp/shibboleth",
         "DisplayNames": [
          {
          "value": "Michigan Technological University",
          "lang": "en"
          }
         ],
         "PrivacyStatementURLs": [
          {
          "value": "http://www.mtu.edu/policy/policies/general/1-06/index.html",
          "lang": "en"
          }
         ],
         "Logos": [
          {
          "value": "https://www.mtu.edu/it/images/it-support-banner.png",
          "height": "70",
          "width": "332",
          "lang": "en"
          }
         ]
        },
        {
         "entityID": "urn:mace:incommon:msu.edu",
         "DisplayNames": [
          {
          "value": "Michigan State University",
          "lang": "en"
          }
         ]
        },
        {
         "entityID": "https://registry.shibboleth.ox.ac.uk/idp",
         "DisplayNames": [
          {
          "value": "University of Oxford",
          "lang": "en"
          }
         ]
        },
        {
         "entityID": "https://idp-test.shibboleth.ox.ac.uk/shibboleth-idp",
         "DisplayNames": [
          {
          "value": "University of Oxford Test IdP",
          "lang": "en"
          }
         ],
         "Descriptions": [
          {
          "value": "University of Oxford Test IdP",
          "lang": "en"
          }
         ]
        },
      {
         "entityID": "https://idp.wmich.edu/idp/shibboleth",
         "DisplayNames": [
          {
          "value": "Western Michigan University",
          "lang": "en"
          }
         ],
         "Descriptions": [
          {
          "value": "Western Michigan University",
          "lang": "en"
          }
         ],
         "InformationURLs": [
          {
          "value": "http://www.wmich.edu/",
          "lang": "en"
          }
         ],
         "PrivacyStatementURLs": [
          {
          "value": "http://www.wmich.edu/it/policies/",
          "lang": "en"
          }
         ],
         "Logos": [
          {
          "value": "https://idp.wmich.edu/idp/images/w_logo.png",
          "height": "150",
          "width": "172",
          "lang": "en"
          }
         ]
        }
      ]
    eos
    obj_disco_feed = JSON.parse(json_disco_feed)
    render json: obj_disco_feed
    # redirect_to "#{Rails.configuration.shibboleth_service_provider_url}/DiscoFeed"
  end

  def ds; end

  def help; end
end
