# frozen_string_literal: true

desc 'Per-publisher CSV to help create EPUB components'
namespace :heliotrope do
  task :components_epub_csv, [:publisher, :visibility] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:components_epub_csv[michigan, all]" > ~/tmp/components_epub_csv_YYYYMMDD.csv

    query = if args.visibility == 'all'
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher}"
            else
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher} AND +visibility_ssi:#{args.visibility}"
            end

    docs = ActiveFedora::SolrService.query(query, rows: 100_000) ;0

    docs.each do |m|
      epub_representative = FeaturedRepresentative.where(monograph_id: m.id, kind: 'epub').first
      puts "#{epub_representative.file_set_id},#{m['doi_ssim']&.first}" if epub_representative.present?
    end

    puts "No monographs found. Check your values for publisher (see code base or UI) and visibility (use 'open', 'restricted' or 'all')" if docs.count.zero?
  end
end
