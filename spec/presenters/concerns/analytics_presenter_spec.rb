# frozen_string_literal: true

require 'rails_helper'

describe AnalyticsPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(fileset_doc, ability) }
  let(:fileset_doc) { SolrDocument.new(id: 'fs') }

  describe "#page_views_by_path" do
    let(:pageviews) {
      [
        OpenStruct.new(date: "20161022", pagePath: "/concern/thing", pageviews: "2"),
        OpenStruct.new(date: "20161111", pagePath: "/concern/stuff", pageviews: "9"),
        OpenStruct.new(date: "20160909", pagePath: "/concern/other", pageviews: "3"),
        OpenStruct.new(date: "20160910", pagePath: "/concern/thing", pageviews: "5")
      ]
    }
    it "when there are pageviews, it returns the pageviews" do
      allow(Rails.cache).to receive(:read).and_return(pageviews)
      expect(presenter.pageviews_by_path("/concern/thing")).to eq 7
    end
    it "when there are no pageviews, it returns 0" do
      allow(Rails.cache).to receive(:read).and_return(pageviews)
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
        OpenStruct.new(date: "20161022", pagePath: "/concern/123", pageviews: "2"),
        OpenStruct.new(date: "20161111", pagePath: "/concern/123?search=dogs", pageviews: "9"),
        OpenStruct.new(date: "20160909", pagePath: "/concern/456", pageviews: "3"),
        OpenStruct.new(date: "20160910", pagePath: "/concern/789", pageviews: "5")
      ]
    }
    it "when there are pageviews, it returns the pageviews" do
      allow(Rails.cache).to receive(:read).and_return(pageviews)
      expect(presenter.pageviews_by_ids(['123', '456'])).to eq 14
    end
    it "when there are no pageviews, it returns 0" do
      allow(Rails.cache).to receive(:read).and_return(pageviews)
      expect(presenter.pageviews_by_ids(['12X', '89Y'])).to eq 0
    end
    it "when there is no cache, it returns '?'" do
      allow(Rails.cache).to receive(:read).and_return(nil)
      expect(presenter.pageviews_by_ids(['123', '456'])).to eq '?'
    end
  end
end
