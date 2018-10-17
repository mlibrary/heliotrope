# frozen_string_literal: true

# for ticket HELIO-1844, to be run when any new Monographs are published under HEB
# This dumps values for all HEB Monographs so that new books that are part of a
# multi-volume title can have their handles processed correctly

desc 'HEB handles'
namespace :heliotrope do
  task handles_heb_all: :environment do
    # Usage: bundle exec rake heliotrope:handles_heb_all > ~/tmp/heb_handles_YYYYMMDD.csv

    # In theory, handles for brand-new content can be created before publication, but HEB has old handles which...
    # we change to point to Fulcrum using the output of this script. We don't want those redirected to draft...
    # monographs. Hence the visibility_ssi: 'open' here.
    monos = Monograph.where(press_sim: 'heb', visibility_ssi: 'open')
    monos.each do |m|
      heb_id = m.identifier.find { |i| i[/^heb[0-9].*/] } || ''
      puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)},#{heb_id}"

      m.ordered_members.to_a.each do |f|
        featured_representative = FeaturedRepresentative.where(monograph_id: f.parent.id, file_set_id: f.id).first
        if featured_representative&.kind == 'epub'
          puts "#{f.id},#{Rails.application.routes.url_helpers.epub_path(f.id)}"
        else
          puts "#{f.id},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f.id)}"
        end
      end
    end
  end
end
