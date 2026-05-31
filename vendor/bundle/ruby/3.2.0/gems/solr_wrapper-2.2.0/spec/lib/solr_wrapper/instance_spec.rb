require 'spec_helper'

describe SolrWrapper::Instance do
  let(:options) { {} }
  let(:solr_instance) { SolrWrapper::Instance.new(options) }
  subject { solr_instance }
  let(:client) { SimpleSolrClient::Client.new(subject.url) }

  describe "#with_collection" do
    let(:options) { { cloud: false } }
    context "without a name" do
      it "creates a new anonymous collection" do
        subject.wrap do |solr|
          solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
            core = client.core(collection_name)
            unless defined? JRUBY_VERSION
              expect(core.schema.field('id').name).to eq 'id'
              expect(core.schema.field('id').stored).to eq true
            end
          end
        end
      end
    end
    context "with a config file" do
      before do
        allow(solr_instance.config).to receive(:collection_options)
          .and_return(name: 'project-development', dir: 'solr/config/')
        allow(solr_instance).to receive(:delete)
      end

      it "creates a new collection with options from the config" do
        expect(solr_instance).to receive(:create).with(
          hash_including(name: "project-development", dir: anything))
        solr_instance.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) {}
      end
    end

    context 'persistent collections' do
      it "creates a new collection with options from the config" do
        expect(solr_instance).to receive(:create).with(
          hash_including(name: 'project-development'))
        expect(solr_instance).not_to receive(:delete)
        solr_instance.with_collection(name: 'project-development', dir: 'solr/config/', persist: true) {}
      end

      describe 'single solr node' do
        it 'allows persistent collection on restart' do
          subject.wrap do |solr|
            solr.with_collection(name: 'solr-node-persistent-core', dir: File.join(FIXTURES_DIR, 'basic_configs'), persist: true) {}
          end

          subject.wrap do |solr|
            solr.with_collection(name: 'solr-node-persistent-core', dir: File.join(FIXTURES_DIR, 'basic_configs'), persist: true) {}
            solr.delete 'solr-node-persistent-core'
          end
        end
      end

      describe 'solr cloud' do
        let(:options) { { cloud: true } }

        it 'allows persistent collection on restart' do
          subject.wrap do |solr|
            config_name = solr.upconfig dir: File.join(FIXTURES_DIR, 'basic_configs')
            solr.with_collection(name: 'solr-cloud-persistent-collection', config_name: config_name, persist: true) {}
          end

          subject.wrap do |solr|
            solr.with_collection(name: 'solr-cloud-persistent-collection', persist: true) {}
            solr.delete 'solr-cloud-persistent-collection'
          end
        end
      end
    end
  end

  context 'with a SolrCloud instance' do
    let(:options) { { cloud: true } }
    it 'can upload configurations' do
      subject.wrap do |solr|
        config_name = solr.upconfig dir: File.join(FIXTURES_DIR, 'basic_configs')
        Dir.mktmpdir do |dir|
          solr.downconfig name: config_name, dir: dir
        end
        solr.with_collection(config_name: config_name) do |collection_name|
          core_name = client.cores.select { |x| x =~ /^#{collection_name}/ }.first
          core = client.core(core_name)
          unless defined? JRUBY_VERSION
            expect(core.all.size).to eq 0
          end
        end
      end
    end

    context 'with a config file' do
      before do
        allow(solr_instance.config).to receive(:configsets)
          .and_return([name: 'project-development', dir: 'solr/config/'])
      end

      it 'creates a new configsets with options from the config' do
        expect(subject).to receive(:upconfig).with(
          hash_including(name: 'project-development', dir: anything))

        subject.wrap do
          # no-op
        end
      end
    end
  end

  describe 'exec' do
    let(:cmd) { 'start' }
    let(:options) { { p: '4098', help: true } }
    subject { solr_instance.send(:exec, cmd, options) }
    it 'runs the command' do
      result_io = subject
      expect(result_io.read).to include('Usage: solr start')
    end
    it 'accepts boolean flags' do
      result_io = solr_instance.send(:exec, 'start', p: '4098', help: true)
      expect(result_io.read).to include('Usage: solr start')
    end

    describe 'when something goes wrong' do
      let(:cmd) { 'healthcheck' }
      let(:options) { { z: 'localhost:5098' } }
      it 'raises an error with the output from the shell command' do
        expect { subject }.to raise_error(RuntimeError, /Failed to execute solr healthcheck: collection parameter is required!/)
      end
    end
  end

  describe "#host" do
    subject { solr_instance.host }
    it { is_expected.to eq '127.0.0.1' }
  end

  describe "#port" do
    subject { solr_instance.port }
    it { is_expected.to eq '8983' }
  end

  describe "#url" do
    subject { solr_instance.url }
    it { is_expected.to eq 'http://127.0.0.1:8983/solr/' }
  end

  describe "#instance_dir" do
    subject { solr_instance.instance_dir }
    it { is_expected.to start_with Dir.tmpdir }
  end

  describe "#version" do
    before do
      allow(solr_instance.config).to receive(:version).and_return('solr-version-number')
    end

    subject { solr_instance.version }
    it { is_expected.to eq 'solr-version-number' }
  end

  describe "#checksum_validator" do
    subject { solr_instance.send(:checksum_validator) }
    it { is_expected.to be_instance_of SolrWrapper::ChecksumValidator }
  end
end
