# frozen_string_literal: true

# This dumps values for all Monographs under a publisher

desc 'publisher handles'
namespace :heliotrope do
  task :handles_publisher, [:publisher, :visibility] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:handles_publisher[michigan, all]" > ~/tmp/handles_publisher_YYYYMMDD.csv

    query = if args.visibility == 'all'
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher}"
            else
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher} AND +visibility_ssi:#{args.visibility}"
            end

    docs = ActiveFedora::SolrService.query(query, rows: 100_000) ;0

    docs.each do |m|
      isbn_value = m['isbn_tesim']&.map { |val| val.sub(/\s*\(.+\)$/, '').delete('^0-9').strip } &.join('; ')
      # the Monograph row for HEB will have the HEB ID
      if args.publisher == 'heb'
        heb_id = m['identifier_tesim']&.find { |i| i.strip.downcase[/^heb_id:\s*heb[0-9]{5}/] }&.strip&.downcase&.gsub(/heb_id:\s*/, '')
        puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)},#{heb_id},#{isbn_value},#{m['doi_ssim']&.first}"
      else
        puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)},#{isbn_value},#{m['doi_ssim']&.first}"
      end

      m['ordered_member_ids_ssim']&.each do |f| # f is just a string, each FileSet's NOID
        puts "#{f},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f)}"
      end
    end

    puts "No monographs found. Check your values for publisher (see code base or UI) and visibility (use 'open', 'restricted' or 'all')" if docs.count.zero?
  end
end
