# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob, type: :job do
  describe "perform" do
    let(:metadata) { double('metadata') }
    let(:register) { double('register') }

    before do
      monograph.members << file_set
      monograph.save!
      allow(Crossref::FileSetMetadata).to receive(:new).and_return(metadata)
      allow(metadata).to receive(:build).and_return(Nokogiri::XML("<xml>hello</xml>"))
      allow(Crossref::Register).to receive(:new).and_return(register)
      allow(register).to receive(:post).and_return(true)
    end

    context "when not making file_set DOIs" do
      let(:press) { create(:press) }
      let(:monograph) { build(:monograph, press: press.subdomain) }
      let(:file_set) { create(:file_set) }

      it "sets the date published" do
        expect(monograph.date_published).to eq []
        described_class.perform_now(monograph)
        expect(monograph.date_published.first).not_to be_nil
        expect(file_set.reload.date_published.first).not_to be_nil

        expect(monograph.read_groups).to eq ['public']
        expect(file_set.read_groups).to eq ['public']

        expect(Crossref::FileSetMetadata).not_to have_received(:new)
        expect(Crossref::Register).not_to have_received(:new)
      end
    end

    context "when making file_set DOIs" do
      let(:press) { create(:press, doi_creation: true) }
      let(:monograph) { build(:monograph, press: press.subdomain, doi: "10.xxx/blah") }
      let(:file_set) { create(:file_set) }

      it "calls FileSet DOI creation" do
        described_class.perform_now(monograph)
        expect(Crossref::FileSetMetadata).to have_received(:new)
        expect(Crossref::Register).to have_received(:new)
      end
    end
  end
end
