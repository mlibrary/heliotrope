require 'rails_helper'

describe CurationConcerns::SectionPresenter do
  let(:ability) { nil }
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, press: press.subdomain) }

  it 'includes TitlePresenter' do
    expect(described_class.new(nil, nil)).to be_a TitlePresenter
  end

  describe "#monograph_label" do
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:attributes) do
      { "id" => "qr46r109z",
        "title_tesim" => ["foo bar"],
        "human_readable_type_tesim" => ["Section"],
        "has_model_ssim" => ["Section"],
        "monograph_id_ssim" => monograph.id
      }
    end
    let(:presenter) { described_class.new(solr_document, ability) }

    it "returns the it's monograph's label" do
      # this call happens in the monograph indexer
      allow(ActiveFedora::SolrService).to receive(:query)
        .with("{!terms f=id}#{monograph.id}")
      allow(ActiveFedora::SolrService).to receive(:query)
        .with("{!terms f=member_ids_ssim}qr46r109z")
        .and_return([{ "member_ids_ssim" => ["qr46r109z"],
                       "title_tesim" => ["My first monograph"] }])

      expect(presenter.monograph_label).to eq 'My first monograph'
    end
  end

  describe "#representative_presenter" do
    let(:file_set) { create(:file_set) }
    let(:section) { create(:section, title: ["Section 1"], representative_id: file_set.id) }
    let(:presenter) { CurationConcerns::PresenterFactory.build_presenters([section.id], described_class, ability).first }

    it "returns a FileSetPresenter" do
      expect(presenter.representative_presenter.class).to eq CurationConcerns::FileSetPresenter
    end
  end

  describe "#monograph" do
    let(:presenter) { described_class.new(SolrDocument.new(id: 'section_id', monograph_id_ssim: monograph.id), ability) }
    it "returns a MonographPresenters" do
      expect(presenter.monograph.class).to eq CurationConcerns::MonographPresenter
    end
  end
end
