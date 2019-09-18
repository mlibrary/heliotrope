# frozen_string_literal: true

desc 'Per-publisher CSV to help create ebook (epub, pdf_ebook or mobi) components'
namespace :heliotrope do
  task :components_ebooks_csv, [:publisher, :ebook_format, :visibility] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:components_epub_csv[michigan, epub, all]" > ~/tmp/components_epub_csv_YYYYMMDD.csv
    # where ebook_format is either epub, pdf_ebook or mobi

    query = if args.visibility == 'all'
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher}"
            else
              "+has_model_ssim:Monograph AND +press_sim:#{args.publisher} AND +visibility_ssi:#{args.visibility}"
            end

    docs = ActiveFedora::SolrService.query(query, rows: 100_000) ;0

    docs.each do |m|
      rep = FeaturedRepresentative.where(work_id: m.id, kind: args.ebook_format).first
      puts "#{rep.file_set_id},#{m['doi_ssim']&.first}" if rep.present?
    end

    puts "No monographs found. Check your values for publisher (see code base or UI) and visibility (use 'open', 'restricted' or 'all')" if docs.count.zero?
  end
end
