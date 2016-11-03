require 'rails_helper'

describe CurationConcerns::FileSetPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(fileset_doc, ability) }
  let(:monograph) { create(:monograph, creator_given_name: "firstname", creator_family_name: "lastname") }
  let(:file_set) { create(:file_set) }
  let(:press) { create(:press, subdomain: 'blue', google_analytics: 'UA-THINGS') }
  before do
    monograph.ordered_members << file_set
    monograph.save!
  end

  it 'includes TitlePresenter' do
    expect(described_class.new(nil, nil)).to be_a TitlePresenter
  end

  describe "handles" do
    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], ext_url_doi_or_handle: ["Handle"], hdl_ssim: ["HANDLE"]) }
    it "has a handle" do
      expect(presenter.hdl.first).to eq 'HANDLE'
      expect(presenter.handle_url).to eq "http://hdl.handle.net/2027/fulcrum.HANDLE"
      expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.HANDLE"
    end
    it "does not have a handle" do
      fileset_doc.to_h['hdl_ssim'][0] = nil
      # right now we're defaulting to the NOID for new things that don't yet have handles
      expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.fileset_id"
    end
  end

  describe "#monograph" do
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name.first).to eq monograph.creator_family_name
    end
  end

  describe '#allow_download?' do
    let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes') }
    it "can download" do
      expect(presenter.allow_download?).to be true
    end
  end

  describe '#subdomain' do
    let(:fileset_doc) { SolrDocument.new(id: 'fs', press_tesim: press.subdomain) }
    it "returns the press subdomain" do
      expect(presenter.subdomain).to eq press.subdomain
    end
  end

  describe "#google_analytics_id" do
    context "when the press has a google analytics id" do
      let(:fileset_doc) { SolrDocument.new(id: 'fs', press_tesim: press.subdomain) }
      it "returns the press google analytics id" do
        expect(presenter.google_analytics_id).to eq press.google_analytics
      end
    end
    context "when the press has no google analytics id, but there's a fulcrum id" do
      let(:fileset_doc) { SolrDocument.new(id: 'fs') }
      it "returns the fulcrum google analytics id" do
        Rails.application.secrets.google_analytics_id = 'UA-YES'
        expect(presenter.google_analytics_id).to eq 'UA-YES'
      end
    end
    context "when the press has no google analytics id and no fulcrum id" do
      let(:fileset_doc) { SolrDocument.new(id: 'fs') }
      it "returns nil" do
        Rails.application.secrets.delete :google_analytics_id
        expect(presenter.google_analytics_id).to be nil
      end
    end
  end

  describe "#pageviews" do
    let(:fileset_doc) { SolrDocument.new(id: 'fs') }
    before do
      allow(presenter).to receive(:pageviews_by_date).and_return(
        [
          { date: "20161003", pageviews: "5" },
          { date: "20161004", pageviews: "1" },
          { date: "20161005", pageviews: "2" }
        ]
      )
    end
    it "has the correct number of pageviews" do
      expect(presenter.pageviews).to eq 8
    end
  end
end
