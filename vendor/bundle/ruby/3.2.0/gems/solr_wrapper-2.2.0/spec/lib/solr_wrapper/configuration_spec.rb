require 'spec_helper'

describe SolrWrapper::Configuration do
  let(:config) { described_class.new options }

  describe "#port" do
    subject { config.port }

    context "when port is set to nil" do
      let(:options) { { port: nil } }
      it { is_expected.to eq nil }
    end

    context "when port is not set" do
      let(:options) { {} }
      it { is_expected.to eq '8983' }
    end

    context "when a port is provided" do
      let(:options) { { port: '8888' } }
      it { is_expected.to eq '8888' }
    end
  end

  describe "#load_configs" do
    before do
      allow(config).to receive(:default_configuration_paths).and_return([])
    end
    context 'with a single config file' do
      let(:options) { { config: 'spec/fixtures/sample_config.yml' } }
      it "uses values from the config file" do
        expect(config.port).to eq '9999'
      end
    end
    context 'with multiple config files' do
      let(:options) { { config: ['spec/fixtures/sample_config.yml', 'spec/fixtures/another_sample_config.yml'] } }
      it "uses values from the config file" do
        expect(config.port).to eq '9998'
        expect(config.verbose?).to eq true
      end
    end
  end

  describe "#collection_options" do
    before do
      allow(config).to receive(:default_configuration_paths).and_return([])
    end
    let(:options) { { config: 'spec/fixtures/sample_config.yml' } }
    it "uses values from the config file" do
      expect(config.collection_options).to eq(name: 'project-development', dir: 'solr/config/', persist: false)
    end
  end

  describe '#configsets' do
    before do
      allow(config).to receive(:default_configuration_paths).and_return([])
    end
    let(:options) { { config: 'spec/fixtures/sample_config.yml' } }

    it 'uses values from the config file' do
      expect(config.configsets).to include(name: 'project-development-configset', dir: 'solr/config/')
    end
  end

  describe '#version' do
    context 'when it is a version number' do
      let(:options) { { version: 'x.y.z' } }

      it 'uses that version' do
        expect(config.version).to eq 'x.y.z'
      end
    end

    context 'when it is "latest"' do
      let(:options) { { version: 'latest'} }

      before do
        stub_request(:get, 'https://lucene.apache.org/solr/downloads.html').to_return(body: 'Solr 1.2.3 is the latest version')
      end

      it 'fetches the latest version number from apache' do
        expect(config.version).to eq '1.2.3'
      end
    end

    context 'when it is "latest" and the latest url is configured' do
      let(:options) { { version: 'latest', latest_version_url: 'https://example.com/latest.html'} }

      before do
        stub_request(:get, 'https://example.com/latest.html').to_return(body: 'Solr 1.2.1')
      end

      it 'fetches the latest version number from apache' do
        expect(config.version).to eq '1.2.1'
      end
    end
  end

  describe '#mirror_url' do
    context 'with a preferred mirror' do
      let(:options) { { mirror_url: 'http://lib-solr-mirror.princeton.edu/dist/', version: '7.2.1' } }

      it 'is the URL to the artifact on the preferred mirror' do
        expect(config.mirror_url).to eq 'http://lib-solr-mirror.princeton.edu/dist/lucene/solr/7.2.1/solr-7.2.1.zip'
      end
    end
  end
end
