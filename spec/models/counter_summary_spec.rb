# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterSummary, type: :model do
  describe 'validations' do
    describe 'presence validations' do
      it 'requires monograph_noid' do
        stat = build(:counter_summary, monograph_noid: nil)
        expect(stat).not_to be_valid
        expect(stat.errors[:monograph_noid]).to include("can't be blank")
      end

      it 'requires month' do
        stat = build(:counter_summary, month: nil)
        expect(stat).not_to be_valid
        expect(stat.errors[:month]).to include("can't be blank")
      end

      it 'requires year' do
        stat = build(:counter_summary, year: nil)
        expect(stat).not_to be_valid
        expect(stat.errors[:year]).to include("can't be blank")
      end
    end

    describe 'numericality validations' do
      it 'validates month is an integer between 1 and 12' do
        expect(build(:counter_summary, month: 0)).not_to be_valid
        expect(build(:counter_summary, month: 13)).not_to be_valid
        expect(build(:counter_summary, month: 1.5)).not_to be_valid
        expect(build(:counter_summary, month: 6)).to be_valid
      end

      it 'validates year is an integer >= 2000' do
        expect(build(:counter_summary, year: 1999)).not_to be_valid
        expect(build(:counter_summary, year: 2000.5)).not_to be_valid
        expect(build(:counter_summary, year: 2025)).to be_valid
      end

      it 'validates all metric fields are non-negative integers' do
        expect(build(:counter_summary, total_item_requests_month: -1)).not_to be_valid
        expect(build(:counter_summary, total_item_investigations_month: -1)).not_to be_valid
        expect(build(:counter_summary, unique_item_requests_month: -1)).not_to be_valid
        expect(build(:counter_summary, unique_item_investigations_month: -1)).not_to be_valid

        expect(build(:counter_summary, total_item_requests_month: 0)).to be_valid
        expect(build(:counter_summary, total_item_requests_month: 100)).to be_valid
      end
    end

    describe 'lifetime_metrics_greater_than_or_equal_to_monthly' do
      it 'is invalid when total_item_requests_life < total_item_requests_month' do
        stat = build(:counter_summary, total_item_requests_life: 5, total_item_requests_month: 10)
        expect(stat).not_to be_valid
        expect(stat.errors[:total_item_requests_life]).to include("must be greater than or equal to monthly requests")
      end

      it 'is invalid when total_item_investigations_life < total_item_investigations_month' do
        stat = build(:counter_summary, total_item_investigations_life: 5, total_item_investigations_month: 10)
        expect(stat).not_to be_valid
        expect(stat.errors[:total_item_investigations_life]).to include("must be greater than or equal to monthly investigations")
      end

      it 'is invalid when unique_item_requests_life < unique_item_requests_month' do
        stat = build(:counter_summary, unique_item_requests_life: 5, unique_item_requests_month: 10)
        expect(stat).not_to be_valid
        expect(stat.errors[:unique_item_requests_life]).to include("must be greater than or equal to monthly unique requests")
      end

      it 'is invalid when unique_item_investigations_life < unique_item_investigations_month' do
        stat = build(:counter_summary, unique_item_investigations_life: 5, unique_item_investigations_month: 10)
        expect(stat).not_to be_valid
        expect(stat.errors[:unique_item_investigations_life]).to include("must be greater than or equal to monthly unique investigations")
      end

      it 'is valid when lifetime metrics equal monthly metrics' do
        stat = build(:counter_summary, total_item_requests_life: 10, total_item_requests_month: 10)
        expect(stat).to be_valid
      end
    end

    describe 'uniqueness' do
      let!(:existing_stat) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 7) }

      it 'prevents duplicate monograph_noid for the same year and month' do
        duplicate = build(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 7)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:monograph_noid]).to include('already has statistics for this month and year')
      end

      it 'allows same monograph_noid for different months' do
        different_month = build(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 8)
        expect(different_month).to be_valid
      end

      it 'allows same monograph_noid for different years' do
        different_year = build(:counter_summary, monograph_noid: 'abc123', year: 2026, month: 7)
        expect(different_year).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:stat1) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 1) }
    let!(:stat2) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 2) }
    let!(:stat3) { create(:counter_summary, monograph_noid: 'xyz789', year: 2025, month: 1) }
    let!(:stat4) { create(:counter_summary, monograph_noid: 'abc123', year: 2024, month: 12) }

    describe '.for_monograph' do
      it 'returns all stats for a specific monograph' do
        expect(described_class.for_monograph('abc123')).to contain_exactly(stat1, stat2, stat4)
      end
    end

    describe '.for_year' do
      it 'returns all stats for a specific year' do
        expect(described_class.for_year(2025)).to contain_exactly(stat1, stat2, stat3)
      end
    end

    describe '.for_month' do
      it 'returns all stats for a specific month' do
        expect(described_class.for_month(1)).to contain_exactly(stat1, stat3)
      end
    end

    describe '.for_period' do
      it 'returns stats for a specific year and month' do
        expect(described_class.for_period(2025, 1)).to contain_exactly(stat1, stat3)
      end
    end

    describe '.recent_months' do
      let!(:stat5) { create(:counter_summary, monograph_noid: 'recent456', year: 2025, month: 3) }
      it 'returns the most recent stats' do
        stats = described_class.recent_months(2)
        expect(stats.map(&:id)).to eq([stat5.id, stat2.id])
      end
    end

    describe '.older_than' do
      it 'returns stats older than the given date' do
        date = Date.new(2025, 2, 1)
        expect(described_class.older_than(date)).to contain_exactly(stat1, stat3, stat4)
      end
    end
  end

  describe '.for_display' do
    let!(:stat1) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 1) }
    let!(:stat2) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 3) }
    let!(:stat3) { create(:counter_summary, monograph_noid: 'abc123', year: 2025, month: 2) }

    it 'returns stats in chronological order' do
      stats = described_class.for_display('abc123', 6)
      expect(stats.map(&:month)).to eq([1, 2, 3])
    end

    it 'limits results to the specified count' do
      stats = described_class.for_display('abc123', 2)
      expect(stats.count).to eq(2)
    end
  end

  describe '.cleanup_old_stats' do
    # Freeze time so cutoff calculations are deterministic
    # old_stat is Jan 2023 (> 24 months from frozen date)
    # recent_stat is March 2025 (13 months from frozen date, < 24 months)
    let!(:old_stat) { create(:counter_summary, year: 2023, month: 1) }
    let!(:recent_stat) { create(:counter_summary, year: 2025, month: 3) }

    around { |example| travel_to(Date.new(2026, 4, 7)) { example.run } }

    it 'deletes statistics older than 24 months (default)' do
      expect {
        described_class.cleanup_old_stats(24)
      }.to change(described_class, :count).by(-1)
      expect(described_class.exists?(old_stat.id)).to be false
      expect(described_class.exists?(recent_stat.id)).to be true
    end

    it 'deletes statistics older than specified months (12)' do
      # With 12 month retention, both records should be deleted
      # old_stat: Jan 2023 (> 12 months old)
      # recent_stat: March 2025 (> 12 months old from April 2026)
      expect {
        described_class.cleanup_old_stats(12)
      }.to change(described_class, :count).by(-2)
    end
  end

  describe '.exists_for_period?' do
    let!(:stat) { create(:counter_summary, year: 2025, month: 3) }

    it 'returns true when stats exist for the period' do
      expect(described_class.exists_for_period?(2025, 3)).to be true
    end

    it 'returns false when stats do not exist for the period' do
      expect(described_class.exists_for_period?(2025, 4)).to be false
    end
  end

  describe '#month_year_string' do
    let(:stat) { create(:counter_summary, year: 2025, month: 7) }

    it 'returns a formatted month-year string' do
      expect(stat.month_year_string).to eq('Jul-2025')
    end
  end
end
