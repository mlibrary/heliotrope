require 'rails_helper'

describe CurationConcerns::SectionPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { "id" => "qr46r109z",
      "title_tesim" => ["foo bar"],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"] }
  end

  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability) }

  let(:response) do
    [{ "member_ids_ssim" => ["qr46r109z"],
       "title_tesim" => ["My first monograph"] }]
  end

  before do
    allow(ActiveFedora::SolrService).to receive(:query)
      .with("{!terms f=member_ids_ssim}qr46r109z")
      .and_return(response)
  end

  describe "#monograph_label" do
    subject { presenter.monograph_label }
    it { is_expected.to eq 'My first monograph' }
  end

  # describe "#monograph_id" do
  #   subject { presenter.monograph_id }
  #   it { is_expected.to eq 'my book' }
  # end
end
