# frozen_string_literal: true

# Book title, Customer, (Country), Chapter Title, Hits
desc 'Per-publisher spreadsheet for royalty calculations'
namespace :heliotrope do
  task :royalty_usage_report, [:copyright_holder, :start_date, :end_date] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:royalty_usage_report[copyright_holder,start_date,end_date]"

    fail 'You must enter a copyright holder search string' unless args.copyright_holder.present?
    fail 'Invalid date format, use YYYY-MM-DD' unless( args.start_date.match(/^\d{4}-\d{2}-\d{2}$/) && args.end_date.match(/^\d{4}-\d{2}-\d{2}$/) )
    fail 'Invalid date range' if Date.parse(args.end_date) < Date.parse(args.start_date) 

    ids = []
    titles = {}
    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph", fl: ['id', 'copyright_holder_tesim', 'title_tesim'], sort: 'id asc', rows: 100000)

    search_term = args.copyright_holder.downcase.strip
    docs.each { |doc| if doc['copyright_holder_tesim']&.first&.downcase&.strip == search_term then ids << doc.id; titles[doc.id] = doc['title_tesim']&.first end }

    puts ['Monograph', 'Customer', 'Section', 'Hits'].to_csv
    data = CounterReport.joins('INNER JOIN institutions ON counter_reports.institution=institutions.id').where(['counter_reports.parent_noid IN (?)', ids]).where(:created_at => args.start_date..args.end_date).where.not(section: nil).group('section,institution,parent_noid').order('parent_noid, institutions.name').pluck("parent_noid, institutions.name, section, count(*)")
    data.each_with_index do |d, i|
      title = titles[d[0]]
      section = d[2].gsub(/\s+/, ' ')
      puts [title, d[1], section, d[3]].to_csv
    end
  end
end
