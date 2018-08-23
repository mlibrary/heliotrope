# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CCAnalyticsPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { Hyrax::FileSetPresenter.new(fileset_doc, ability) }
  let(:fileset_doc) { SolrDocument.new(id: 'fs') }

  before do
    allow(fileset_doc).to receive(:date_uploaded).and_return(DateTime.strptime('1514764800000', '%Q')) # 20180101
  end

  describe "pageviews" do
    before { allow(Rails.cache).to receive(:read).and_return(pageviews) }

    describe "#page_views_by_path" do
      let(:pageviews) {
        [
          OpenStruct.new(date: "20170102", pagePath: "/concern/thing", pageviews: "999"), # will be excluded
          OpenStruct.new(date: "20180102", pagePath: "/concern/thing", pageviews: "2"),
          OpenStruct.new(date: "20180104", pagePath: "/concern/stuff", pageviews: "9"),
          OpenStruct.new(date: "20180105", pagePath: "/concern/other", pageviews: "3"),
          OpenStruct.new(date: "20140107", pagePath: "/concern/thing", pageviews: "5000"), # will be excluded
          OpenStruct.new(date: "20180107", pagePath: "/concern/thing", pageviews: "5")
        ]
      }

      it "when there are pageviews, it returns the pageviews since date_uploaded" do
        expect(presenter.pageviews_by_path("/concern/thing")).to eq 7
      end
      it "when there are no pageviews, it returns 0" do
        expect(presenter.pageviews_by_path("/concern/newthing")).to eq 0
      end
      it "when there is no cache, it returns '?'" do
        allow(Rails.cache).to receive(:read).and_return(nil)
        expect(presenter.pageviews_by_path("/concern/thing")).to eq '?'
      end
    end

    describe "#page_views_by_ids" do
      let(:pageviews) {
        [
          OpenStruct.new(date: "20170102", pagePath: "/concern/123", pageviews: "999"), # will be excluded
          OpenStruct.new(date: "20180102", pagePath: "/concern/123", pageviews: "2"),
          OpenStruct.new(date: "20180104", pagePath: "/concern/123?search=dogs", pageviews: "9"),
          OpenStruct.new(date: "20180105", pagePath: "/concern/456", pageviews: "3"),
          OpenStruct.new(date: "20160105", pagePath: "/concern/456", pageviews: "9999"), # will be excluded
          OpenStruct.new(date: "20180107", pagePath: "/concern/789", pageviews: "5")
        ]
      }

      describe "aggregated counts (pageviews_by_ids)" do
        it "when there are pageviews, it returns the pageviews since date_uploaded" do
          expect(presenter.pageviews_by_ids(['123', '456'])).to eq 14
        end
        it "when there are no pageviews, it returns 0" do
          expect(presenter.pageviews_by_ids(['12X', '89Y'])).to eq 0
        end
        it "when there is no cache, it returns '?'" do
          allow(Rails.cache).to receive(:read).and_return(nil)
          expect(presenter.pageviews_by_ids(['123', '456'])).to eq '?'
        end
      end

      describe "aggregated counts per day (timestamped_pageviews_by_ids) since date_uploaded" do
        it "when there are pageviews, it returns a hash of timestamps => pageviews and sets pageviews count" do
          expect(presenter.timestamped_pageviews_by_ids(['123', '456'])).to match a_hash_including(DateTime.strptime('20180102', '%Y%m%d').strftime('%Q').to_i => 2,
                                                                                                   DateTime.strptime('20180104', '%Y%m%d').strftime('%Q').to_i => 9,
                                                                                                   DateTime.strptime('20180105', '%Y%m%d').strftime('%Q').to_i => 3)
          expect(presenter.pageviews).to eq 14
        end
        it "when there are no pageviews, it returns an empty hash and sets pageviews count" do
          pageviews_hash = presenter.timestamped_pageviews_by_ids(['12X', '89Y'])
          expect(pageviews_hash).to be_a(Hash)
          expect(pageviews_hash.keys.count).to eq 0
          expect(presenter.pageviews).to eq 0
        end
        it "when there is no cache, it returns an empty hash and sets pageviews count to '?'" do
          allow(Rails.cache).to receive(:read).and_return(nil)
          pageviews_hash = presenter.timestamped_pageviews_by_ids(['123', '456'])
          expect(pageviews_hash).to be_a(Hash)
          expect(pageviews_hash.keys.count).to eq 0
          expect(presenter.pageviews).to eq '?'
        end
      end
    end
  end

  describe 'Flot graph data functions' do
    describe '#flot_daily_pageviews_zero_pad' do
      subject { presenter.flot_daily_pageviews_zero_pad(['foo', 'bar']) }

      let(:pageviews_hash) {
        { 1_514_937_600_000 => 2, # 20180103
          1_515_196_800_000 => 9, # 20180106
          1_515_283_200_000 => 3 }
      } # 20180107

      let(:graph_data) {
        [[1_514_764_800_000, 0], [1_514_851_200_000, 0], [1_514_937_600_000, 2],
         [1_515_024_000_000, 0], [1_515_110_400_000, 0], [1_515_196_800_000, 9],
         [1_515_283_200_000, 3], [1_515_369_600_000, 0], [1_515_456_000_000, 0],
         [1_515_542_400_000, 0]]
      }

      it 'returns pageview data for a Flot area graph (date_uploaded to "today", padded with 0 pageview days)' do
        allow(DateTime).to receive(:yesterday).and_return(DateTime.strptime('1515542400000', '%Q')) # 20180110
        allow(presenter).to receive(:timestamped_pageviews_by_ids).and_return(pageviews_hash)
        expect(subject).to eq graph_data
      end
    end

    before do
      allow(DateTime).to receive(:yesterday).and_return(DateTime.strptime('1518048000000', '%Q')) # 20180208
    end

    describe '#flot_pageviews_over_time, with activity in the last 30 days' do
      subject { presenter.flot_pageviews_over_time(['foo', 'bar']) }

      let(:pageviews_hash) {
        { 1_514_937_600_000 => 2, # 20180103
          1_515_196_800_000 => 9,    # 20180106
          1_515_283_200_000 => 3,    # 20180107
          1_515_542_400_000 => 6 }
      } # 20180110

      let(:graph_data) {
        [[1_514_764_800_000, 0],
         [1_514_937_600_000, 2],
         [1_515_196_800_000, 11],
         [1_515_283_200_000, 14],
         [1_515_542_400_000, 20]]
      }

      it 'returns pageview data where each value is the total views to date' do
        allow(presenter).to receive(:timestamped_pageviews_by_ids).and_return(pageviews_hash)
        expect(subject).to eq graph_data
      end
    end

    describe '#flot_pageviews_over_time, with no activity in the last 30 days' do
      subject { presenter.flot_pageviews_over_time(['foo', 'bar']) }

      let(:pageviews_hash) {
        { 1_514_937_600_000 => 2, # 20180103
          1_515_196_800_000 => 9, # 20180106
          1_515_283_200_000 => 3 }
      }       # 20180107

      let(:graph_data) {
        [[1_514_764_800_000, 0],
         [1_514_937_600_000, 2],
         [1_515_196_800_000, 11],
         [1_515_283_200_000, 14],
         [1_518_048_000_000, 14]]
      }       # an added value for 20180208, "yesterday"

      it 'returns pageview data where each value is the total views to date, adding a final value for yesterday' do
        allow(presenter).to receive(:timestamped_pageviews_by_ids).and_return(pageviews_hash)
        expect(subject).to eq graph_data
      end
    end
  end
end
