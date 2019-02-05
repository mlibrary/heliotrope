# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestfulFedora do
  describe '#reindex_everything' do
    let(:restful_fedora) { double('restful_fedora') }
    let(:contains) { [] }

    before do
      allow(RestfulFedora::Service).to receive(:new).and_return(restful_fedora)
      allow(restful_fedora).to receive(:contains).and_return(contains)
      allow(ActiveFedora::SolrService).to receive(:commit)
    end

    it do
      described_class.reindex_everything
      expect(ActiveFedora::SolrService).to have_received(:commit)
    end

    context 'something' do
      let(:contains) { [uri] }
      let(:uri) { described_class.url + '/' + object_path }
      let(:object_path) { described_class.base_path + '/va/li/dn/oi/' + object_id }
      let(:object_id) { 'validnoid' }
      let(:object) { double('object') }
      let(:object_to_solr) { double('object_to_solr') }
      let(:descendant_fetcher) { double('descendant_fetcher') }
      let(:descendant_path) { described_class.base_path + '/no/id/va/li/' + descendant_id }
      let(:descendant_id) { 'noidvalid' }
      let(:descendant) { double('descendants') }
      let(:descendant_to_solr) { double('descendant_to_solr') }
      let(:descendants) { [object_path, descendant_path] }
      let(:batch) { [object_to_solr, descendant_to_solr] }

      before do
        allow(ActiveFedora::Base).to receive(:find).with(object_id).and_return(object)
        allow(ActiveFedora::Base).to receive(:find).with(descendant_id).and_return(descendant)
        allow(ActiveFedora::Indexing::DescendantFetcher).to receive(:new).with(object_path).and_return(descendant_fetcher)
        allow(descendant_fetcher).to receive(:descendant_and_self_uris).and_return(descendants)
        allow(object).to receive(:to_solr).and_return(object_to_solr)
        allow(descendant).to receive(:to_solr).and_return(descendant_to_solr)
        allow(ActiveFedora::SolrService).to receive(:add).with(batch, softCommit: true)
      end

      it do
        described_class.reindex_everything
        expect(ActiveFedora::SolrService).to have_received(:add)
        expect(ActiveFedora::SolrService).to have_received(:commit)
      end
    end
  end

  describe '#url' do
    subject { described_class.url }

    it { is_expected.to eq ActiveFedora.config.credentials[:url] }
  end

  describe '#base_path' do
    subject { described_class.base_path }

    it { is_expected.to eq ActiveFedora.config.credentials[:base_path].gsub(/^./, '') }
  end

  describe '#uri_to_path' do
    subject { described_class.uri_to_path(uri) }

    let(:uri) { described_class.url + '/' + described_class.base_path + prefix + id }
    let(:prefix) { '/va/li/dn/oi/' }
    let(:id) { 'validnoid' }

    it { is_expected.to eq described_class.base_path + prefix + id }

    context 'invalid uri' do
      let(:uri) { described_class.url + '/' + prefix + id }

      it { is_expected.to eq uri }
    end
  end

  describe '#path_to_id' do
    subject { described_class.path_to_id(path) }

    let(:path) { described_class.base_path + prefix + id }
    let(:prefix) { '/va/li/dn/oi/' }
    let(:id) { 'validnoid' }

    it { is_expected.to eq id }

    context 'invalid path' do
      before { allow(ActiveFedora::Base).to receive(:uri_to_id).with(path).and_raise(StandardError) }

      it { is_expected.to eq path }
    end
  end

  describe '#id_to_object' do
    subject { described_class.id_to_object(id) }

    let(:id) { 'validnoid' }
    let(:object) { double('object') }

    before { allow(ActiveFedora::Base).to receive(:find).with(id).and_return(object) }

    it { is_expected.to eq object }

    context 'not found' do
      before { allow(ActiveFedora::Base).to receive(:find).with(id).and_raise(StandardError) }

      it { is_expected.to eq nil }
    end
  end
end
