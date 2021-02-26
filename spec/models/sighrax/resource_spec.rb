# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Resource, type: :model do
  describe 'monograph resource' do
    subject { Sighrax.from_noid(resource.id) }

    let(:resource) { create(:public_file_set, content: File.open(File.join(fixture_path, 'present.txt'))) }
    let(:monograph) { create(:public_monograph) }

    before do
      monograph.ordered_members << resource
      monograph.save
      resource.save
    end

    it 'has expected values' do
      is_expected.not_to be_an_instance_of described_class
      is_expected.to be_an_instance_of Sighrax::Asset # Deprecated
      is_expected.to be_a_kind_of Sighrax::Model
      expect(subject.resource_type).not_to eq :Resource
      expect(subject.resource_type).to eq :Asset # Deprecated

      expect(subject.allow_download?).to be false
      expect(subject.content).to eq 'present'
      expect(subject.downloadable?).to be true
      expect(subject.file_name).to eq 'present.txt'
      expect(subject.file_size).to eq 7
      expect(subject.media_type).to eq 'text/plain'
      expect(subject.parent.noid).to eq monograph.id
      expect(subject.parent.children.first.noid).to eq resource.id
      expect(subject.watermarkable?).to be false
    end
  end

  describe '#allow_download?' do
    subject { Sighrax.from_noid(resource.id).allow_download? }

    let(:resource) { create(:public_file_set) }

    it { is_expected.to be false }

    context 'when allow download yes' do
      before do
        resource.allow_download = 'yes'
        resource.save
      end

      it { is_expected.to be true }
    end
  end

  describe '#downloadable?' do
    subject { Sighrax.from_noid(resource.id).downloadable? }

    let(:resource) { create(:public_file_set) }

    it { is_expected.to be true }

    context 'when external resource' do
      before do
        resource.external_resource_url = 'https://foo.com/resource.html'
        resource.save
      end

      it { is_expected.to be false }
    end
  end
end
