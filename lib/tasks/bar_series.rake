# frozen_string_literal: true

desc 'Input to Greensub assigning titles to Products'
namespace :heliotrope do
  task :bar_series, [:series, :scope] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:bar_series[brit, all]" > ~/tmp/bar_series_csv_YYYYMMDD.csv
    # where series is 'brit' or 'int'
    # and scope is e.g., 'YYYY', 'pre2019','all' (CURRENTLY DEFAULTS TO ALL)

    series = args[:series]
    scope = args[:scope] || 'all'
    all_series = ['brit', 'int']
    fail "Unknown series value '#{args[:series]}' not in #{all_series}" unless all_series.include? args[:series]
    assign_bar_series(series, scope)
  end

  def assign_bar_series(series, scope)
    checker = nil
    year = nil
    if match = scope.match(/^(pre)?(\d\d\d\d)$/i)
      if match.captures[0]
        checker = ->(y1, y2) { y1 < y2 }
      else
        checker = ->(y1, y2) { y1 == y2 }
      end
      year = match.captures[1]
    elsif scope != 'all'
      fail "Don't know what to do with scope value '#{scope}'"
    end
    series_q = series == 'brit' ? 'British' : 'International'
    q = "+has_model_ssim:Monograph AND +press_sim:barpublishing AND +series_tesim:#{series_q}"
    docs = ActiveFedora::SolrService.query(q, rows: 100_000)
    docs.each do |doc|
      unless checker.nil?
        y = doc['date_created_tesim'][0][0..3]
        next unless checker.call(y, year)
      end
      sd = SolrDocument.new(doc)
      mp = Hyrax::MonographPresenter.new(sd, nil)
      puts "#{mp.id},#{mp.bar_number}"
    end
    puts "No monographs found. Check your values for series ('brit', 'int') and scope" if docs.count.zero?
  end
end


