require 'rails_helper'

describe SolrDocument do
  let(:instance) { described_class.new(attributes) }

  describe "#date_published" do
    let(:attributes) { { 'date_published_tesim' => ['Oct 20th'] } }
    subject { instance.date_published }
    it { is_expected.to eq ['Oct 20th'] }
  end
end
