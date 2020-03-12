# frozen_string_literal: true

class PublisherStatsJob < ApplicationJob
  def perform(stats_file)
    presses = []
    Press.order(:name).each do |press|
      presses.append(stats(press))
    end
    File.open(stats_file, 'w') { |file| file.write({ presses: presses, timestamp: Time.now.utc.to_s }.to_yaml) }
  end

  private

    def stats(press)
      publisher = Sighrax::Publisher.from_press(press)
      monograph_count = publisher.work_noids.count
      asset_count = publisher.asset_noids.count
      user_count = publisher.user_ids.count
      trash_flag = !(monograph_count.positive? || asset_count.positive? || user_count.positive? || publisher.children.present?)
      {
        subdomain: press.subdomain,
        name: press.name,
        monographs: monograph_count,
        assets: asset_count,
        users: user_count,
        trash: trash_flag
      }
    end
end
