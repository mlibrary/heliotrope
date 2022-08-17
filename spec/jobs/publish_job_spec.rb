# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob, type: :job do
  describe "perform" do
    let(:metadata) { double('metadata') }
    let(:register) { double('register') }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
      allow(Crossref::FileSetMetadata).to receive(:new).and_return(metadata)
      allow(metadata).to receive(:build).and_return(Nokogiri::XML("<xml>hello</xml>"))
      allow(Crossref::Register).to receive(:new).and_return(register)
      allow(register).to receive(:post).and_return(true)
    end

    context "file_sets inherit read and edit groups" do
      let(:press) { create(:press) }
      let(:monograph) do
        create(:monograph, press: press.subdomain,
                           read_groups: ["#{press.subdomain}_admin"],
                           edit_groups: ["#{press.subdomain}_admin"])
      end
      let(:file_set) { create(:file_set) }

      it "has the monograph's read and edit groups" do
        described_class.perform_now(file_set)
        expect(file_set.reload.read_groups).to include("#{press.subdomain}_admin")
        expect(file_set.reload.read_groups).to include("public")
        expect(file_set.reload.edit_groups).to include("#{press.subdomain}_admin")
      end
    end

    context "when press does not have file_set DOI creation set" do
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

    context "when press has file_set DOI creation set" do
      let(:press) { create(:press, doi_creation: true) }
      let(:monograph) { build(:monograph, press: press.subdomain, doi: doi) }
      let(:file_set) { create(:file_set) }

      context "monograph has no doi set" do
        let(:doi) { nil }

        it "does not raise an error or call file_set DOI creation" do
          expect { described_class.perform_now(monograph) }.not_to raise_error(NoMethodError)
          expect(Crossref::FileSetMetadata).not_to have_received(:new)
          expect(Crossref::Register).not_to have_received(:new)
        end
      end

      context "monograph has a DOI set" do
        let(:doi) { "10.xxx/blah" }

        it "calls FileSet DOI creation" do
          described_class.perform_now(monograph)
          expect(Crossref::FileSetMetadata).to have_received(:new)
          expect(Crossref::Register).to have_received(:new)
        end
      end
    end
  end
end
