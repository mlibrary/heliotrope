# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Asset, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Asset }
  it { expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity) }

  describe '#parent' do
    let(:data) { { 'monograph_id_ssim' => [noid] } }
    let(:parent) { double('parent') }

    before { allow(Sighrax).to receive(:from_noid).with(noid).and_return(parent) }

    it { expect(subject.parent).to be parent }
  end

  context 'content, media_type, filename' do
    it do
      expect(subject.content).to eq ''
      expect(subject.media_type).to eq 'text/plain'
      expect(subject.filename). to eq noid + '.txt'
    end

    context 'original_file' do
      let(:file_set) { double('file_set') }
      let(:original_file) { double('original_file', mime_type: 'mime_type', file_name: ['file_name']) }
      let(:content) { double('content') }

      before do
        allow(FileSet).to receive(:find).with(noid).and_return(file_set)
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(original_file).to receive(:content).and_return(content)
      end

      it do
        expect(subject.content).to be content
        expect(subject.media_type).to eq 'mime_type'
        expect(subject.filename).to eq 'file_name'
      end
    end
  end
end
