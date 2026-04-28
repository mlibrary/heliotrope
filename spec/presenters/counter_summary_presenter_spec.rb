# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterSummaryPresenter do
  subject(:presenter) { described_class.new(monograph_noid) }

  let(:monograph_noid) { 'test123noid' }

  describe '#initialize' do
    it 'sets the monograph_noid' do
      expect(presenter.monograph_noid).to eq(monograph_noid)
    end
  end

  describe '#statistics' do
    context 'with no statistics' do
      it 'returns an empty array' do
        expect(presenter.statistics).to eq([])
      end
    end

    context 'with statistics' do
      let!(:stat1) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 10) }
      let!(:stat2) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 11) }
      let!(:stat3) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 12) }
      let!(:other_stat) { create(:counter_summary, monograph_noid: 'other_noid', year: 2025, month: 10) }

      it 'returns statistics for the monograph in chronological order' do
        stats = presenter.statistics
        expect(stats.length).to eq(3)
        expect(stats.map(&:month)).to eq([10, 11, 12])
        expect(stats).not_to include(other_stat)
      end

      it 'caches the statistics' do
        expect(CounterSummary).to receive(:for_display).once.with(monograph_noid, 6).and_call_original
        presenter.statistics
        presenter.statistics # Second call should use cached value
      end

      it 'limits to 6 months by default' do
        # Create more than 6 months of data
        7.times do |i|
          create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: i + 1)
        end

        stats = presenter.statistics
        expect(stats.length).to eq(6)
      end
    end
  end

  describe '#any_statistics?' do
    context 'with no statistics' do
      it 'returns false' do
        expect(presenter.any_statistics?).to be false
      end
    end

    context 'with statistics' do
      before do
        create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 10)
      end

      it 'returns true' do
        expect(presenter.any_statistics?).to be true
      end
    end
  end

  describe '#most_recent' do
    context 'with no statistics' do
      it 'returns nil' do
        expect(presenter.most_recent).to be_nil
      end
    end

    context 'with statistics' do
      let!(:stat1) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 10) }
      let!(:stat2) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 11) }
      let!(:stat3) { create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 12) }

      it 'returns the most recent statistic' do
        expect(presenter.most_recent).to eq(stat3)
      end
    end
  end

  describe '#month_headers' do
    context 'with statistics' do
      before do
        create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 10)
        create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 11)
        create(:counter_summary, monograph_noid: monograph_noid, year: 2025, month: 12)
      end

      it 'returns formatted month-year strings' do
        headers = presenter.month_headers
        expect(headers).to eq(['Oct-2025', 'Nov-2025', 'Dec-2025'])
      end
    end

    context 'with no statistics' do
      it 'returns an empty array' do
        expect(presenter.month_headers).to eq([])
      end
    end
  end

  describe '#monthly_data_for' do
    let!(:stat1) do
      create(:counter_summary,
             monograph_noid: monograph_noid,
             year: 2025,
             month: 10,
             total_item_requests_month: 100)
    end
    let!(:stat2) do
      create(:counter_summary,
             monograph_noid: monograph_noid,
             year: 2025,
             month: 11,
             total_item_requests_month: 150)
    end

    it 'returns an array of values for the specified metric' do
      data = presenter.monthly_data_for('total_item_requests_month')
      expect(data).to eq([100, 150])
    end
  end

  describe '#life_total_for' do
    context 'with statistics' do
      let!(:stat1) do
        create(:counter_summary,
               monograph_noid: monograph_noid,
               year: 2025,
               month: 10,
               total_item_requests_life: 1000)
      end
      let!(:stat2) do
        create(:counter_summary,
               monograph_noid: monograph_noid,
               year: 2025,
               month: 11,
               total_item_requests_life: 1200)
      end

      it 'returns the life total from the most recent month' do
        expect(presenter.life_total_for('total_item_requests_life')).to eq(1200)
      end
    end

    context 'with no statistics' do
      it 'returns 0' do
        expect(presenter.life_total_for('total_item_requests_life')).to eq(0)
      end
    end
  end

  describe 'metric type constants and methods' do
    describe 'METRIC_TYPES' do
      it 'has the correct metric mappings' do
        expect(described_class::METRIC_TYPES).to eq({
                                                       'Total_Item_Investigations' => 'total_item_investigations_month',
                                                       'Total_Item_Requests' => 'total_item_requests_month',
                                                       'Unique_Item_Investigations' => 'unique_item_investigations_month',
                                                       'Unique_Item_Requests' => 'unique_item_requests_month'
                                                     })
      end
    end

    describe 'LIFE_METRIC_TYPES' do
      it 'has the correct life metric mappings' do
        expect(described_class::LIFE_METRIC_TYPES).to eq({
                                                            'Total_Item_Investigations' => 'total_item_investigations_life',
                                                            'Total_Item_Requests' => 'total_item_requests_life',
                                                            'Unique_Item_Investigations' => 'unique_item_investigations_life',
                                                            'Unique_Item_Requests' => 'unique_item_requests_life'
                                                          })
      end
    end

    describe '#metric_type_names' do
      it 'returns metric type display names' do
        expect(presenter.metric_type_names).to eq([
                                                     'Total_Item_Investigations',
                                                     'Total_Item_Requests',
                                                     'Unique_Item_Investigations',
                                                     'Unique_Item_Requests'
                                                   ])
      end
    end

    describe '#monthly_column_for' do
      it 'returns the correct monthly column name' do
        expect(presenter.monthly_column_for('Total_Item_Requests')).to eq('total_item_requests_month')
      end
    end

    describe '#life_column_for' do
      it 'returns the correct life column name' do
        expect(presenter.life_column_for('Total_Item_Requests')).to eq('total_item_requests_life')
      end
    end
  end

  describe 'integration with real data' do
    let!(:jan) do
      create(:counter_summary,
             monograph_noid: monograph_noid,
             year: 2025,
             month: 10,
             total_item_requests_month: 100,
             total_item_requests_life: 1000,
             total_item_investigations_month: 150,
             total_item_investigations_life: 1500,
             unique_item_requests_month: 80,
             unique_item_requests_life: 800,
             unique_item_investigations_month: 120,
             unique_item_investigations_life: 1200)
    end

    let!(:feb) do
      create(:counter_summary,
             monograph_noid: monograph_noid,
             year: 2025,
             month: 11,
             total_item_requests_month: 120,
             total_item_requests_life: 1120,
             total_item_investigations_month: 180,
             total_item_investigations_life: 1680,
             unique_item_requests_month: 90,
             unique_item_requests_life: 890,
             unique_item_investigations_month: 140,
             unique_item_investigations_life: 1340)
    end

    it 'provides all data needed for the view' do
      expect(presenter.any_statistics?).to be true
      expect(presenter.month_headers).to eq(['Oct-2025', 'Nov-2025'])

      # Check monthly data
      expect(presenter.monthly_data_for('total_item_requests_month')).to eq([100, 120])
      expect(presenter.monthly_data_for('total_item_investigations_month')).to eq([150, 180])
      expect(presenter.monthly_data_for('unique_item_requests_month')).to eq([80, 90])
      expect(presenter.monthly_data_for('unique_item_investigations_month')).to eq([120, 140])

      # Check life totals (should be from most recent month)
      expect(presenter.life_total_for('total_item_requests_life')).to eq(1120)
      expect(presenter.life_total_for('total_item_investigations_life')).to eq(1680)
      expect(presenter.life_total_for('unique_item_requests_life')).to eq(890)
      expect(presenter.life_total_for('unique_item_investigations_life')).to eq(1340)
    end
  end
end
