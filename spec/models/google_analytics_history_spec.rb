# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleAnalyticsHistory, type: :model do
  describe "uniqueness" do
    before do
      create(:google_analytics_history, noid: '1',
                                        original_date: '20180101',
                                        page_path: '/concern/thing/1',
                                        pageviews: 1)
    end

    it "all fields together must be unique" do
      expect(described_class.create(noid: '1',
                                    original_date: '20180101',
                                    page_path: '/concern/thing/1',
                                    pageviews: 1)).not_to be_valid
    end
  end
end
