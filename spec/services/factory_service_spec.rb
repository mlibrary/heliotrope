# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FactoryService do
  let(:monograph) { create(:monograph) }
  let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
  let(:mcsv) { create(:file_set, content: File.open(File.join(fixture_path, 'csv/import/tempest.csv'))) }
  let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }

  before do
    monograph.ordered_members << epub << webgl
    monograph.save!
    epub.save!
    webgl.save!
    FeaturedRepresentative.create(monograph_id: monograph.id, file_set_id: epub.id, kind: 'epub')
    FeaturedRepresentative.create(monograph_id: monograph.id, file_set_id: webgl.id, kind: 'webgl')
    described_class.clear_caches
  end
  after { FeaturedRepresentative.destroy_all }
  after(:all) { described_class.clear_caches } # rubocop:disable RSpec/BeforeAfterAll

  describe '#nop' do
    it { expect(described_class).to respond_to(:nop) }
  end

  describe '#clear_semaphores' do
    it { expect(described_class).to respond_to(:clear_semaphores) }
  end

  describe '#clear_caches' do
    subject { described_class.clear_caches }

    it "calls each child's clear cache" do
      expect(described_class).to receive(:clear_e_pub_publication_cache).ordered
      expect(described_class).to receive(:clear_mcsv_manifest_cache).ordered
      expect(described_class).to receive(:clear_webgl_unity_cache).ordered
      expect(described_class).to receive(:clear_semaphores).ordered
      subject
    end
  end

  describe '#clear_e_pub_publication_cache' do
    subject { described_class.clear_e_pub_publication_cache }

    let(:id) { epub.id }

    it 'caches the publication' do
      old_publication = described_class.e_pub_publication(id)
      new_publication = described_class.e_pub_publication(id)
      expect(old_publication).to eq new_publication
    end

    it 'clears the cache' do
      old_publication = described_class.e_pub_publication(id)
      expect(old_publication).to receive(:purge)
      expect(EPub::Publication).to receive(:clear_cache)
      subject
      new_publication = described_class.e_pub_publication(id)
      expect(old_publication).not_to eq new_publication
    end
  end

  describe '#clear_mcsv_manifest_cache' do
    subject { described_class.clear_mcsv_manifest_cache }

    let(:id) { mcsv.id }

    it 'caches the manifest' do
      old_manifest = described_class.mcsv_manifest(id)
      new_manifest = described_class.mcsv_manifest(id)
      expect(old_manifest).to eq new_manifest
    end

    it 'clears the cache' do
      old_manifest = described_class.mcsv_manifest(id)
      expect(old_manifest).to receive(:purge)
      expect(MCSV::Manifest).to receive(:clear_cache)
      subject
      new_manifest = described_class.mcsv_manifest(id)
      expect(old_manifest).not_to eq new_manifest
    end
  end

  describe '#clear_webgl_unity_cache' do
    subject { described_class.clear_webgl_unity_cache }

    let(:id) { webgl.id }

    it 'caches the webgl' do
      old_webgl = described_class.webgl_unity(id)
      new_webgl = described_class.webgl_unity(id)
      expect(old_webgl).to eq new_webgl
    end

    it 'clears the cache' do
      old_webgl = described_class.webgl_unity(id)
      expect(old_webgl).to receive(:purge)
      expect(Webgl::Unity).to receive(:clear_cache)
      subject
      new_webgl = described_class.webgl_unity(id)
      expect(old_webgl).not_to eq new_webgl
    end
  end

  describe '#purge_e_pub_publication' do
    subject { described_class.purge_e_pub_publication(id) }

    let(:id) { epub.id }

    it 'purges the publication' do
      old_publication = described_class.e_pub_publication(id)
      expect(old_publication).to receive(:purge)
      subject
      new_publication = described_class.e_pub_publication(id)
      expect(old_publication).not_to eq new_publication
    end
  end

  describe '#purge_mcsv_manifest' do
    subject { described_class.purge_mcsv_manifest(id) }

    let(:id) { mcsv.id }

    it 'purges the manifest' do
      old_manifest = described_class.mcsv_manifest(id)
      expect(old_manifest).to receive(:purge)
      subject
      new_manifest = described_class.mcsv_manifest(id)
      expect(old_manifest).not_to eq new_manifest
    end
  end

  describe '#purge_webgl_unity' do
    subject { described_class.purge_webgl_unity(id) }

    let(:id) { webgl.id }

    it 'purges the webgl' do
      old_webgl = described_class.webgl_unity(id)
      expect(old_webgl).to receive(:purge)
      subject
      new_webgl = described_class.webgl_unity(id)
      expect(old_webgl).not_to eq new_webgl
    end
  end

  describe '#e_pub_publication' do
    subject { described_class.e_pub_publication(id) }

    context 'nil id' do
      let(:id) { nil }
      it 'returns a null object' do
        expect(Rails.logger).to receive(:info).with("FactoryService.e_pub_publication() '' is NOT a valid noid.")
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end
    context 'object not found' do
      let(:id) { 'validnoid' }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end
    context 'file set is an epub' do
      let(:id) { epub.id }
      it 'returns an epub publication' do
        is_expected.to be_an_instance_of(EPub::Publication)
        expect(subject.id).to eq id
      end
    end
    context 'file set is not an epub' do
      let(:id) { mcsv.id }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end
  end

  describe '#mcsv_manifest' do
    subject { described_class.mcsv_manifest(id) }

    context 'nil id' do
      let(:id) { nil }
      it 'returns a null object' do
        expect(Rails.logger).to receive(:info).with("FactoryService.mcsv_manifest() '' is NOT a valid noid.")
        is_expected.to be_an_instance_of(MCSV::ManifestNullObject)
      end
    end
    context 'object not found' do
      let(:id) { 'validnoid' }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(MCSV::ManifestNullObject)
      end
    end
    context 'file set is a manifest' do
      let(:id) { mcsv.id }
      it 'returns a manifest file' do
        is_expected.to be_an_instance_of(MCSV::Manifest)
      end
    end
    context 'file set is not a manifest' do
      let(:id) { epub.id }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(MCSV::ManifestNullObject)
      end
    end
  end

  describe '#webgl_unity' do
    subject { described_class.webgl_unity(id) }

    context 'nil id' do
      let(:id) { nil }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(Webgl::UnityNullObject)
      end
    end

    context 'file set is a webgl' do
      let(:id) { webgl.id }
      it 'returns a webgl unity object' do
        is_expected.to be_an_instance_of(Webgl::Unity)
        expect(subject.id).to eq id
      end
    end
  end
end
