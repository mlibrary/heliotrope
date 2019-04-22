# frozen_string_literal: true

class PublisherStatsJob < ApplicationJob
  def perform(stats_file)
    presses = []
    Press.order(:name).each do |press|
      presses.push(
        subdomain: press.subdomain,
        name: press.name,
        monographs: monograph_ids(press).count,
        assets: asset_ids(press).count,
        users: user_ids(press).count
      )
    end
    File.open(stats_file, 'w') { |file| file.write({ presses: presses, timestamp: Time.now.utc.to_s }.to_yaml) }
  end

  private

    def monograph_ids(press = nil)
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph", rows: 10_000)
      ids = []
      docs.each do |doc|
        if press.nil?
          ids << doc['id']
        elsif doc['press_tesim']&.first == press.subdomain
          ids << doc['id']
        end
      end
      ids
    end

    def asset_ids(press = nil)
      asset_ids = []
      monograph_ids(press).each do |monograph_id|
        monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{monograph_id}", rows: 1)
        if monograph_doc.present?
          asset_ids += monograph_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)] || []
        end
      end
      asset_ids
    end

    def user_ids(press = nil)
      return User.all.map(&:id) if press.nil?
      User.joins("INNER JOIN roles ON roles.user_id = users.id AND roles.resource_id = #{press.id} AND roles.resource_type = 'Press'").map(&:id)
    end
end
