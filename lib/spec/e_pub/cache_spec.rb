# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../support/e_pub_helper'

RSpec.describe EPub::Cache do
  let(:noid) { 'validnoid' }
  let(:non_noid) { 'invalidnoid' }
  let(:id) { double("id") }
  let(:path) { double("path") }

  before do
    allow(EPubsService).to receive(:epub_path).with(id).and_return(path)
  end

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#cache' do
    subject { described_class.cache(id, nil) }

    before do
      @called = false
      allow(EPubsService).to receive(:cache_epub).with(id) { @called = true }
      allow(Dir).to receive(:exist?).with(EPubsService.epub_path(id)).and_return(false)
      subject
    end

    context 'non noid' do
      let(:id) { non_noid }
      it { expect(@called).to be false }
    end
    context 'noid' do
      let(:id) { noid }
      it { expect(@called).to be true }
    end
  end

  describe '#cached?' do
    subject { described_class.cached?(id) }

    before do
      allow(Dir).to receive(:exist?).with(EPubsService.epub_path(id)).and_return(cached)
    end

    context 'non noid' do
      let(:id) { non_noid }

      context 'not cached' do
        let(:cached) { false }
        it { is_expected.to be false }
      end
      context 'cached' do
        let(:cached) { true }
        it { is_expected.to be false }
      end
    end
    context 'noid' do
      let(:id) { noid }
      context 'not cached' do
        let(:cached) { false }
        it { is_expected.to be false }
      end
      context 'cached' do
        let(:cached) { true }
        it { is_expected.to be true }
      end
    end
  end

  describe '#clear' do
    subject { described_class.clear }

    before do
      @called = false
      allow(EPubsService).to receive(:clear_cache) { @called = true }
      subject
    end

    it { expect(@called).to be true }
  end

  describe '#epub' do
    subject { described_class.epub(id) }

    before do
      allow(Dir).to receive(:exist?).with(EPubsService.epub_path(id)).and_return(cached)
    end

    context 'non noid' do
      let(:id) { non_noid }
      context 'not cached' do
        let(:cached) { false }
        it { is_expected.to be_an_instance_of(EPub::EPubNullObject) }
      end
      context 'cached' do
        let(:cached) { true }
        it { is_expected.to be_an_instance_of(EPub::EPubNullObject) }
      end
    end

    context 'noid' do
      let(:id) { noid }
      context 'not cached' do
        let(:cached) { false }
        it { is_expected.to be_an_instance_of(EPub::EPubNullObject) }
      end
      context 'cached' do
        let(:cached) { true }
        it { is_expected.to be_an_instance_of(EPub::EPub) }
      end
    end
  end

  describe '#prune' do
    subject { described_class.prune }

    before do
      @called = false
      allow(EPubsService).to receive(:prune_cache) { @called = true }
      subject
    end

    it { expect(@called).to be true }
  end

  describe '#purge' do
    subject { described_class.purge(id) }

    before do
      @called = false
      allow(EPubsService).to receive(:prune_cache_epub).with(id) { @called = true }
      subject
    end

    context 'non noid' do
      let(:id) { non_noid }
      it { expect(@called).to be false }
    end
    context 'noid' do
      let(:id) { noid }
      it { expect(@called).to be true }
    end
  end
end
