# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tmm::FileService do
  before do
    stub_out_redis
  end

  let(:pdf) { Rails.root.join(fixture_path, 'hello.pdf') }

  describe "#add" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, title: ["Book"], depositor: user.email) }
    let(:doc) { SolrDocument.new(monograph.to_solr) }

    let(:cover) { Rails.root.join(fixture_path, 'csv', 'import', 'shipwreck.jpg') }
    let(:epub) { Rails.root.join(fixture_path, 'moby-dick.epub') }


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

    before do
      # in the presence of stub_out_redis, these never gets set, making the checks on the existing FileSet meaningless
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:original_checksum)
                                                            .and_return([Digest::MD5.file(file1).hexdigest])
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:probable_image?).and_return(true)
    end

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
        expect(described_class.replace?(file_set_id: file_set.id, new_file_path: file2)).to be true
      end
    end

    context "with a file that is not of the same type" do
      it "raises an exception" do
        expect { described_class.replace?(file_set_id: file_set.id, new_file_path: pdf) }
                   .to raise_error("The FileSet #{file_set.id} does not match the type of the new file.")
      end
    end
  end

  describe "#mismatched_types?" do
    let(:presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new({}), nil) }

    context "image FileSet" do
      before { allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:probable_image?).and_return(true) }

      context "mismatched with another image?" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.jpg', presenter)).to be false
        end
      end

      context "mismatched with a non-image?" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.blah', presenter)).to be true
        end
      end
    end

    context "pdf FileSet" do
      before { allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:pdf?).and_return(true) }

      context "mismatched with another pdf?" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.pdf', presenter)).to be false
        end
      end

      context "mismatched with a non-pdf?" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.blah', presenter)).to be true
        end
      end
    end

    context "image FileSet" do
      before { allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:epub?).and_return(true) }

      context "mismatched with another epub" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.epub', presenter)).to be false
        end
      end

      context "mismatched with a non-epub" do
        it "returns true" do
          expect(described_class.mismatched_types?('blah.blah', presenter)).to be true
        end
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
