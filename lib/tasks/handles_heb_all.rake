# frozen_string_literal: true

# for ticket HELIO-1844, to be run when any new Monographs are published under HEB
# This dumps values for all HEB Monographs so that new books that are part of a
# multi-volume title can have their handles processed correctly

desc 'HEB handles'
namespace :heliotrope do
  task handles_heb_all: :environment do
    # Usage: bundle exec rake heliotrope:handles_heb_all > /tmp/heb_handles_YYYMMMDD.csv
    monos = Monograph.where(press_sim: 'heb')
    monos.each do |m|
      heb_id = m.identifier.find { |i| i[/^heb[0-9].*/] } || ''
      puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)},#{heb_id}"
    end
  end
end
