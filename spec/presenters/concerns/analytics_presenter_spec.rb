require 'rails_helper'

describe AnalyticsPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(fileset_doc, ability) }
  let(:press) { create(:press, subdomain: 'blue', google_analytics: 'UA-THINGS') }
  let(:fileset_doc) { SolrDocument.new(id: 'fs') }

  describe "#google_analytics_id" do
    context "when the press has a google analytics id" do
      let(:fileset_doc) { SolrDocument.new(id: 'fs', press_tesim: press.subdomain) }
      it "returns the press google analytics id" do
        expect(presenter.google_analytics_id).to eq press.google_analytics
      end
    end
    context "when the press has no google analytics id, but there's a fulcrum id" do
      it "returns the fulcrum google analytics id" do
        Rails.application.secrets.google_analytics_id = 'UA-YES'
        expect(presenter.google_analytics_id).to eq 'UA-YES'
      end
    end
    context "when the press has no google analytics id and no fulcrum id" do
      it "returns nil" do
        Rails.application.secrets.delete :google_analytics_id
        expect(presenter.google_analytics_id).to be nil
      end
    end
  end

  describe "#google_analytics_profile" do
    context "when there is a valid profile" do
      it "returns the profile" do
        allow(AnalyticsService).to receive(:profile).and_return(Legato::Management::Profile.new('', ''))
        expect(presenter.google_analytics_profile).to be_a Legato::Management::Profile
      end
    end
    context "when there is not a valid profile" do
      it "returns []" do
        allow(AnalyticsService).to receive(:profile).and_return(nil)
        expect(presenter.google_analytics_profile).to eq []
      end
    end
  end

  describe "#pageviews_by_path" do
    it "returns the correct number of pageviews" do
      allow(AnalyticsService).to receive(:profile).and_return(Legato::Management::Profile.new('', ''))
      allow(Pageview).to receive(:results).and_return(
        [
          OpenStruct.new(date: "20161022", pagePath: "/concern/thing", pageviews: "2"),
          OpenStruct.new(date: "20161111", pagePath: "/concern/stuff", pageviews: "9"),
          OpenStruct.new(date: "20160909", pagePath: "/concern/other", pageviews: "3"),
          OpenStruct.new(date: "20160910", pagePath: "/concern/thing", pageviews: "5")
        ]
      )
      expect(presenter.pageviews_by_path("/concern/thing")).to eq 7
    end
  end

  describe "#pageviews_by_ids" do
    it "returns the correct number of pageviews" do
      allow(AnalyticsService).to receive(:profile).and_return(Legato::Management::Profile.new('', ''))
      allow(Pageview).to receive(:results).and_return(
        [
          OpenStruct.new(date: "20161022", pagePath: "/concern/A", pageviews: "2"),
          OpenStruct.new(date: "20161111", pagePath: "/concern/B", pageviews: "9"),
          OpenStruct.new(date: "20160909", pagePath: "/concern/C", pageviews: "3"),
          OpenStruct.new(date: "20160910", pagePath: "/concern/D", pageviews: "5")
        ]
      )
      expect(presenter.pageviews_by_ids(['A', 'C', 'D'])).to eq 10
    end
  end
end
