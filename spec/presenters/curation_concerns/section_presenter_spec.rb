require 'rails_helper'

describe CurationConcerns::SectionPresenter do
  let(:ability) { nil }

  describe "#monograph_label" do
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:attributes) do
      { "id" => "qr46r109z",
        "title_tesim" => ["foo bar"],
        "human_readable_type_tesim" => ["Section"],
        "has_model_ssim" => ["Section"],
        "monograph_id_ssim" => "dr26xx448"
      }
    end
    let(:presenter) { described_class.new(solr_document, ability) }

    it "returns the it's monograph's label" do
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
end
