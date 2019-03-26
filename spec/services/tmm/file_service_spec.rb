# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tmm::FileService do
  before do
    stub_out_redis
  end

  describe "#add" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, title: ["Book"], depositor: user.email) }
    let(:doc) { SolrDocument.new(monograph.to_solr) }

    let(:cover) { Rails.root.join(fixture_path, 'csv', 'import', 'shipwreck.jpg') }
    let(:epub) { Rails.root.join(fixture_path, 'moby-dick.epub') }
    let(:pdf) { Rails.root.join(fixture_path, 'hello.pdf') }

    it "adds files" do
      described_class.add(doc: doc, file: cover, kind: :cover)
      described_class.add(doc: doc, file: epub, kind: :epub)
      described_class.add(doc: doc, file: pdf, kind: :pdf)

      monograph.reload
      ordered_members = monograph.ordered_members

      expect(ordered_members.to_a.size).to eq 3
      expect(ordered_members.to_a[0].label).to eq 'shipwreck.jpg'

      expect(ordered_members.to_a[1].label).to eq 'moby-dick.epub'
      expect(ordered_members.to_a[1].allow_download).to eq 'yes'
      expect(FeaturedRepresentative.where(file_set_id: ordered_members.to_a[1].id, kind: 'epub').present?).to be true

      expect(ordered_members.to_a[2].label).to eq 'hello.pdf'
      expect(ordered_members.to_a[2].allow_download).to eq 'yes'
      expect(FeaturedRepresentative.where(file_set_id: ordered_members.to_a[2].id, kind: 'pdf_ebook').present?).to be true
    end
  end

  describe "#replace?" do
    let(:file1) { Rails.root.join(fixture_path, 'csv', 'shipwreck.jpg') }
    let(:file2) { Rails.root.join(fixture_path, 'csv', 'miranda.jpg') }
    let(:file_set) { create(:file_set, content: File.open(file1)) }

    context "with the same file" do
      it "returns false" do
        expect(described_class.replace?(file_set_id: file_set.id, new_file_path: file1)).to be false
      end
    end

    context "with a different file" do
      # With files from TMM they will actually have the same name (based on isbn), but
      # for this test it's a different name. It doesn't really matter though, we only
      # care about the checksum.
      it "returns true" do
        expect(described_class.replace?(file_set_id: file_set.id, new_file_path: file2)).to be false
      end
    end
  end

  describe "#replace" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, title: ["Book"], depositor: user.email) }
    let(:doc) { SolrDocument.new(monograph.to_solr) }

    let(:cover) { Rails.root.join(fixture_path, 'csv', 'import', 'shipwreck.jpg') }
    let(:file_set) { create(:file_set, content: File.open(cover)) }

    # Again, in TMM importing current and new covers will actually have the same name, but
    # replace() doesn't care about that. In the future, when we start dealing with
    # "resources"/assets that may need to change(?)
    let(:new_cover) { Rails.root.join(fixture_path, 'csv', 'miranda.jpg') }

    let(:cover_size) { File.size(cover) }
    let(:new_cover_size) { File.size(new_cover) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it "replaces the file_set" do
      expect(cover_size).not_to eq new_cover_size

      described_class.replace(file_set_id: file_set.id, new_file_path: new_cover)
      file_set.reload

      expect(file_set.original_file.size).not_to eq cover_size
      expect(file_set.original_file.size).to eq new_cover_size
      expect(described_class.replace?(file_set_id: file_set.id, new_file_path: new_cover)).to be false
    end
  end
end
