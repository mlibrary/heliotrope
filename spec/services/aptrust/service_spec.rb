# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aptrust::Service do
  let(:filename) { Rails.root.join('config', 'aptrust.yml') }
  let(:file) { instance_double(File, 'file') }
  let(:yaml) { { 'AptrustApiUrl' => 'aptrust_api_url' } }
  let(:connection) { class_double(Faraday, 'connection') }

  before do
    allow(File).to receive(:exist?).with(filename).and_return(true)
    allow(File).to receive(:read).with(filename).and_return(file)
    allow(YAML).to receive(:safe_load).with(file).and_return(yaml)
    allow(Faraday).to receive(:new).with('aptrust_api_url').and_return(connection)
  end

  describe '#connection' do
    let(:yaml) { { 'AptrustApiUrl' => 'http://test.host', 'AptrustApiUser' => 'User', 'AptrustApiKey' => 'Key' } }

    before do
      allow(Faraday).to receive(:new).with('http://test.host').and_call_original
    end

    it 'configured for json' do
      conn = described_class.new.send(:connection)

      expect(conn).to be_a(Faraday::Connection)
      expect(conn.headers['Accept']).to eq('application/json')
      expect(conn.headers['Content-Type']).to eq('application/json')
      expect(conn.headers['X-Pharos-API-User']).to eq('User')
      expect(conn.headers['X-Pharos-API-Key']).to eq('Key')
      expect(conn.options['open_timeout']).to eq(60)
      expect(conn.options['timeout']).to eq(60)
    end
  end

  describe '#ingest_status' do
    subject(:ingest_status) { described_class.new.ingest_status(identifier) }

    let(:identifier) { 'identifier' }
    let(:response) { instance_double(Faraday::Response, 'response', success?: success, body: body) }
    let(:success) { false }
    let(:body) { { "results" => items } }
    let(:items) { [] }

    before { allow(connection).to receive(:get).with("items?object_identifier=#{identifier}&item_action=Ingest").and_return(response) }

    it { is_expected.to eq('http_error') }

    context 'response' do
      let(:success) { true }

      it { is_expected.to eq('not_found') }

      context 'items' do
        let(:items) { [{ "stage" => stage, "status" => status }] }
        let(:stage) { "StAgE" }
        let(:status) { "StAtUs" }

        it { is_expected.to eq('processing') }

        context 'Cleanup' do
          let(:stage) { "ClEaNuP" }

          it { is_expected.to eq('processing') }

          context 'Success' do
            let(:status) { "SuCcEsS" }

            it { is_expected.to eq('success') }

            context 'standard error' do
              before { allow(connection).to receive(:get).with("items?object_identifier=#{identifier}&item_action=Ingest").and_raise(StandardError) }

              it { is_expected.to eq('standard_error') }
            end
          end

          context 'Failed' do
            let(:status) { "FaIlEd" }

            it { is_expected.to eq('failed') }
          end

          context 'Cancelled' do
            let(:status) { "CaNcElLEd" }

            it { is_expected.to eq('failed') }
          end
        end
      end
    end
  end
end
