# frozen_string_literal: true

# HELIO-4115 - this is no longer used but is left in place as inspiration for the next solution

require 'rails_helper'

RSpec.describe StatsGraphService do
  subject { described_class.new('validnoid', Date.strptime('1514764800000', '%Q')) } # 20180101

  before { allow(Date).to receive(:yesterday).and_return(Date.strptime('1518048000000', '%Q')) } # 20180208

  context 'with activity on `date_uploaded`` and in the last 30 days' do
    before do
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180101", page_path: 'concern/thing/1', pageviews: 1)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180102", page_path: 'concern/thing/1', pageviews: 2)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180104", page_path: 'concern/thing/1', pageviews: 9)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180105", page_path: 'concern/thing/2', pageviews: 3)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180107", page_path: 'concern/thing/3', pageviews: 5)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180202", page_path: 'concern/thing/3', pageviews: 5)
    end

    let(:json_graph_data) { "[{\"label\":\"Total Pageviews\",\"data\":[[1514764800000,1],[1514851200000,3]," \
                            "[1515024000000,12],[1515110400000,15],[1515283200000,20],[1517529600000,25]]}]" }

    it 'returns all pageviews graph data; returns correct pageview total' do
      expect(subject.pageviews_over_time_graph_data).to eq json_graph_data
      expect(subject.pageviews).to eq 25
    end
  end

  context 'with no activity on `date_uploaded` or in the last 30 days' do
    before do
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180102", page_path: 'concern/thing/1', pageviews: 2)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180104", page_path: 'concern/thing/1', pageviews: 9)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180105", page_path: 'concern/thing/2', pageviews: 3)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180107", page_path: 'concern/thing/3', pageviews: 5)
    end

    let(:json_graph_data) { "[{\"label\":\"Total Pageviews\",\"data\":[[1514764800000,0],[1514851200000,2]," \
                            "[1515024000000,11],[1515110400000,14],[1515283200000,19],[1518048000000,19]]}]" }

    it 'adds 0 point for date_uploaded and final point for "yesterday", for scale; returns correct pageview total' do
      expect(subject.pageviews_over_time_graph_data).to eq json_graph_data
      expect(subject.pageviews).to eq 19
    end
  end

  context 'with pageviews from before `date_uploaded`' do
    before do
      create(:google_analytics_history, noid: 'validnoid', original_date: "20170102", page_path: 'concern/thing/1', pageviews: 1)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20170102", page_path: 'concern/thing/1?stuff', pageviews: 4)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180101", page_path: 'concern/thing/1', pageviews: 1)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180102", page_path: 'concern/thing/1', pageviews: 2)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180104", page_path: 'concern/thing/1', pageviews: 9)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180105", page_path: 'concern/thing/2', pageviews: 13)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20160105", page_path: 'concern/thing/2', pageviews: 1)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180107", page_path: 'concern/thing/3', pageviews: 5)
      create(:google_analytics_history, noid: 'validnoid', original_date: "20180202", page_path: 'concern/thing/3', pageviews: 5)
    end

    let(:json_graph_data) { "[{\"label\":\"Total Pageviews\",\"data\":[[1514764800000,1],[1514851200000,3]," \
                            "[1515024000000,12],[1515110400000,25],[1515283200000,30],[1517529600000,35]]}]"}

    it 'returns pageviews graph data with these nonsensical values removed; returns correct pageview total' do
      expect(subject.pageviews_over_time_graph_data).to eq json_graph_data
      expect(subject.pageviews).to eq 35
    end
  end
end
