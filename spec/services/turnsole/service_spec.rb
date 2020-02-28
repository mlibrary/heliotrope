# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Turnsole::Service do
  subject(:service) { described_class.new(token, base) }

  let(:token) { double('token') }
  let(:base) { double('base') }
  let(:faraday) { double('faraday') }
  let(:response) { double('response', success?: success, body: body) }
  let(:success) { false }
  let(:body) { double('body') }

  before do
    allow(Faraday).to receive(:new)
    allow(Faraday).to receive(:new).with(base).and_return(faraday)
  end

  describe '#connection' do
    let(:base) { 'http://test.host' }
    let(:token) { 'token' }

    before do
      allow(Faraday).to receive(:new).with(base).and_call_original
    end

    it 'configured for json' do
      conn = service.send(:connection)

      expect(conn).to be_a(Faraday::Connection)
      expect(conn.headers['Accept']).to eq('application/json, application/vnd.heliotrope.v1+json')
      expect(conn.headers['Authorization']).to eq('Bearer token')
      expect(conn.headers['Content-Type']).to eq('application/json')
      expect(conn.options['open_timeout']).to eq(60)
      expect(conn.options['timeout']).to eq(600)
    end
  end

  describe '#find_press' do
    subject { service.find_press(subdomain) }

    let(:subdomain) { 'subdomain' }
    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("press", subdomain: subdomain).and_return(response)
    end

    it { is_expected.to eq(nil) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      before do
        allow(body).to receive(:[]).with('id').and_return(id)
      end

      it { is_expected.to eq(id) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("press", subdomain: subdomain).and_raise(StandardError)
        end

        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#presses' do
    subject { service.presses }

    before do
      allow(faraday).to receive(:get).with('presses').and_return(response)
    end

    it { is_expected.to eq([]) }

    context 'success' do
      let(:success) { true }

      it { is_expected.to eq(body) }

      context 'Standard Error' do
        before { allow(faraday).to receive(:get).with('presses').and_raise(StandardError) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#press' do
    subject { service.press(id) }

    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("presses/#{id}").and_return(response)
    end

    it { is_expected.to eq(nil) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      before do
        allow(body).to receive(:[]).with('id').and_return(id)
      end

      it { is_expected.to eq(id) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("presses/#{id}").and_raise(StandardError)
        end

        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#press_monographs' do
    subject { service.press_monographs(id) }

    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("presses/#{id}/monographs").and_return(response)
    end

    it { is_expected.to eq([]) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      before do
        allow(body).to receive(:[]).with('id').and_return(id)
      end

      it { is_expected.to eq(body) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("presses/#{id}/monographs").and_raise(StandardError)
        end

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#monographs' do
    subject { service.monographs }

    before do
      allow(faraday).to receive(:get).with('monographs').and_return(response)
    end

    it { is_expected.to eq([]) }

    context 'success' do
      let(:success) { true }

      it { is_expected.to eq(body) }

      context 'Standard Error' do
        before { allow(faraday).to receive(:get).with('monographs').and_raise(StandardError) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#monograph' do
    subject { service.monograph(id) }

    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("monographs/#{id}").and_return(response)
    end

    it { is_expected.to eq(nil) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      before do
        allow(body).to receive(:[]).with('id').and_return(id)
      end

      it { is_expected.to eq(id) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("monographs/#{id}").and_raise(StandardError)
        end

        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#monograph_extract' do
    subject { service.monograph_extract(id) }

    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("monographs/#{id}/extract").and_return(response)
    end

    it { is_expected.to eq(body) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      it { is_expected.to eq(body) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("monographs/#{id}/extract").and_raise(StandardError)
        end

        it { is_expected.to eq('StandardError') }
      end
    end
  end

  describe '#monograph_manifest' do
    subject { service.monograph_manifest(id) }

    let(:id) { 'validnoid' }

    before do
      allow(faraday).to receive(:get).with("monographs/#{id}/manifest").and_return(response)
    end

    it { is_expected.to eq(body) }

    context 'success' do
      let(:success) { true }
      let(:body) { double('body') }

      it { is_expected.to eq(body) }

      context 'standard error' do
        before do
          allow(faraday).to receive(:get).with("monographs/#{id}/manifest").and_raise(StandardError)
        end

        it { is_expected.to eq('StandardError') }
      end
    end
  end
end
