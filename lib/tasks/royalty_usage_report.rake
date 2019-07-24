# frozen_string_literal: true

# Book title, Customer, (Country), Chapter Title, Hits
desc 'Per-publisher spreadsheet for royalty calculations'
namespace :heliotrope do
  task :royalty_usage_report, [:press] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:royalty_usage_report[jhu|oup]"
    case args.press
    when 'jhu'
      ids = jhu_ids
    when 'oup'
      ids = oup_ids
    else
      puts "Unknown press '#{args.press} -- should be a subdomain name."
      exit
    end
    puts ['Monograph', 'Customer', 'Section', 'Hits'].to_csv
    data = CounterReport.joins('INNER JOIN institutions ON counter_reports.institution=institutions.id').where(['counter_reports.parent_noid IN (?)', ids]).where(:created_at => '2019-01-01'..'2019-06-30').where.not(section: nil).group('section,institution,parent_noid').order('parent_noid, institutions.name').pluck("parent_noid, institutions.name, section, count(*)")
    data.each_with_index do |d, i|
      begin
        title = Monograph.find(d[0]).title[0]
      rescue
        title = '(Monograph not found)'
      end
      section = d[2].gsub(/\s+/, ' ')
      puts [title, d[1], section, d[3]].to_csv
    end
  end
  
  def jhu_ids
    ActiveFedora::SolrService.query("+copyright_holder_tesim:'Johns%20Hopkins%20University%20Press'", rows: 100_000).map { |d| d.id }
  end
  
  def oup_ids
    ActiveFedora::SolrService.query("+copyright_holder_tesim:'Oxford%20University%20Press'", rows: 100_000).map { |d| d.id }
  end
end

