# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { Hyrax::FileSetPresenter.new(fileset_doc, ability) }
  let(:fileset_doc) { SolrDocument.new(id: 'fs') }

  before do
    allow(fileset_doc).to receive(:date_uploaded).and_return(Date.strptime('1514764800000', '%Q')) # 20180101
  end

  describe "#timestamped_pageviews_by_ids" do
    before { allow(Rails.cache).to receive(:read).and_return(pageviews) }

    let(:pageviews) do
      {
        "111111111" => { "20170102" => 1, "20180102" => 2, "20180104" => 9 },
        "222222222" => { "20180105" => 3, "20160105" => 1 },
        "333333333" => { "20180107" => 5 }
      }
    end

    context "aggregated counts per day (timestamped_pageviews_by_ids) since date_uploaded" do
      it "when there are pageviews, it returns a hash of timestamps => pageviews and sets pageviews count" do
        expect(presenter.timestamped_pageviews_by_ids(['111111111', '222222222'])).to match a_hash_including(Date.strptime('20180102', '%Y%m%d').strftime('%Q').to_i => 2,
                                                                                                             Date.strptime('20180104', '%Y%m%d').strftime('%Q').to_i => 9,
                                                                                                             Date.strptime('20180105', '%Y%m%d').strftime('%Q').to_i => 3)
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
        pageviews_hash = presenter.timestamped_pageviews_by_ids(['111111111', '222222222'])
        expect(pageviews_hash).to be_a(Hash)
        expect(pageviews_hash.keys.count).to eq 0
        expect(presenter.pageviews).to eq '?'
      end
    end
  end

  describe 'Flot graph data functions' do
    before do
      allow(Date).to receive(:yesterday).and_return(Date.strptime('1518048000000', '%Q')) # 20180208
    end

    describe '#flot_pageviews_over_time' do
      subject { presenter.flot_pageviews_over_time(['foo', 'bar']) }

      context 'with activity in the last 30 days' do
        let(:pageviews_hash) do
          {
            1_514_937_600_000 => 2, # 20180103
            1_515_196_800_000 => 9, # 20180106
            1_515_283_200_000 => 3, # 20180107
            1_515_542_400_000 => 6  # 20180110
          }
        end

        let(:graph_data) do
          [[1_514_764_800_000, 0],
           [1_514_937_600_000, 2],
           [1_515_196_800_000, 11],
           [1_515_283_200_000, 14],
           [1_515_542_400_000, 20]]
        end

        it 'returns pageview data where each value is the total views to date' do
          allow(presenter).to receive(:timestamped_pageviews_by_ids).and_return(pageviews_hash)
          expect(subject).to eq graph_data
        end
      end

      context 'with no activity in the last 30 days' do
        let(:pageviews_hash) do
          {
            1_514_937_600_000 => 2, # 20180103
            1_515_196_800_000 => 9, # 20180106
            1_515_283_200_000 => 3  # 20180107
          }
        end

        let(:graph_data) do
          [[1_514_764_800_000, 0],
           [1_514_937_600_000, 2],
           [1_515_196_800_000, 11],
           [1_515_283_200_000, 14],
           [1_518_048_000_000, 14]] # an added value for 20180208, "yesterday"
        end

        it 'returns pageview data where each value is the total views to date, adding a final value for yesterday' do
          allow(presenter).to receive(:timestamped_pageviews_by_ids).and_return(pageviews_hash)
          expect(subject).to eq graph_data
        end
      end
    end
  end
end
