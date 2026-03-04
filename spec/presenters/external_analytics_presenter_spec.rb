# frozen_string_literal: true

require 'rails_helper'

describe ExternalAnalyticsPresenter do
  let(:secrets) { double('secrets', google_analytics_4_id: 'G-TESTID') }
  let(:settings) { double('settings', host: 'www.fulcrum.org') }
  let(:mock_controller) { double('controller', current_institutions: []).as_null_object }
  let(:press_presenter) { double('press_presenter', present?: true, all_google_analytics_4: 'G-PRESSID') }

  subject(:presenter) { described_class.new(mock_controller, press_presenter) }

  before do
    rails_stub = double('Rails').as_null_object
    stub_const('Rails', rails_stub)
    allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
    allow(Rails).to receive_message_chain(:application, :secrets).and_return(secrets)
    stub_const('Settings', settings)
  end

  describe '#development?' do
    it 'returns true if Rails.env.development? and GA4 id present' do
      allow(Rails).to receive_message_chain(:env, :development?).and_return(true)
      expect(presenter.development?).to be true
    end

    it 'returns false if not development' do
      allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      expect(presenter.development?).to be false
    end

    it 'returns false if GA4 id not present' do
      allow(secrets).to receive(:google_analytics_4_id).and_return(nil)
      allow(Rails).to receive_message_chain(:env, :development?).and_return(true)
      expect(presenter.development?).to be false
    end
  end

  describe '#preview?' do
    it 'returns true if host is preview' do
      allow(settings).to receive(:host).and_return('heliotrope-preview.hydra.lib.umich.edu')
      expect(presenter.preview?).to be true
    end
    it 'returns false otherwise' do
      allow(settings).to receive(:host).and_return('other-host')
      expect(presenter.preview?).to be false
    end
  end

  describe '#production?' do
    it 'returns true if host is production, GA4 id present, and not excluded institution' do
      allow(settings).to receive(:host).and_return('www.fulcrum.org')
      allow(mock_controller).to receive(:current_institutions).and_return([])
      expect(presenter.production?).to be true
    end

    it 'returns false if host is not production' do
      allow(settings).to receive(:host).and_return('other-host')
      expect(presenter.production?).to be false
    end

    it 'returns false if GA4 id not present' do
      allow(secrets).to receive(:google_analytics_4_id).and_return(nil)
      allow(settings).to receive(:host).and_return('www.fulcrum.org')
      expect(presenter.production?).to be false
    end

    it 'returns false if institution is excluded' do
      allow(mock_controller).to receive(:current_institutions).and_return([double('institution', identifier: '490')])
      allow(settings).to receive(:host).and_return('www.fulcrum.org')
      expect(presenter.production?).to be false
    end
  end

  describe '#primary_ga4_id' do
    it 'returns GA4 id if present' do
      allow(secrets).to receive(:google_analytics_4_id).and_return('G-TESTID')
      expect(presenter.primary_ga4_id).to eq('G-TESTID')
    end
  end

  describe '#primary_ga4_id?' do
    it 'returns true if GA4 id present' do
      allow(secrets).to receive(:google_analytics_4_id).and_return('G-TESTID')
      expect(presenter.primary_ga4_id?).to be true
    end
    it 'returns false if GA4 id not present' do
      allow(secrets).to receive(:google_analytics_4_id).and_return(nil)
      expect(presenter.primary_ga4_id?).to be false
    end
  end

  describe '#press_ga4_ids' do
    it 'returns press GA4 ids if press presenter present and has ids' do
      allow(press_presenter).to receive(:present?).and_return(true)
      allow(press_presenter).to receive(:all_google_analytics_4).and_return('G-PRESSID')
      expect(presenter.press_ga4_ids).to eq('G-PRESSID')
    end
    it 'returns empty array if press presenter not present' do
      allow(press_presenter).to receive(:present?).and_return(false)
      expect(presenter.press_ga4_ids).to eq([])
    end
    it 'returns empty array if press presenter has no ids' do
      allow(press_presenter).to receive(:present?).and_return(true)
      allow(press_presenter).to receive(:all_google_analytics_4).and_return(nil)
      expect(presenter.press_ga4_ids).to eq([])
    end
  end

  describe '#tag_manager_id?' do
    describe 'preview' do
      it 'returns true if host is preview' do
        allow(settings).to receive(:host).and_return('heliotrope-preview.hydra.lib.umich.edu')
        expect(presenter.tag_manager_id?).to be true
      end
    end
    describe 'production' do
      it 'returns true if host is production and GA4 id present and not excluded institution' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        allow(mock_controller).to receive(:current_institutions).and_return([])
        expect(presenter.tag_manager_id?).to be true
      end
      it 'returns false if host is production but GA4 id not present' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        allow(secrets).to receive(:google_analytics_4_id).and_return(nil)
        expect(presenter.tag_manager_id?).to be false
      end
      it 'returns false if host is production but institution is excluded' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        allow(mock_controller).to receive(:current_institutions).and_return([double('institution', identifier: '490')])
        expect(presenter.tag_manager_id?).to be false
      end
    end
    it 'returns false otherwise' do
      allow(settings).to receive(:host).and_return('other-host')
      expect(presenter.tag_manager_id?).to be false
    end
  end

  describe '#tag_manager_id' do
    it 'returns correct id for preview' do
      allow(settings).to receive(:host).and_return('heliotrope-preview.hydra.lib.umich.edu')
      expect(presenter.tag_manager_id).to eq('GTM-PTZXSV7')
    end
    describe 'production' do
      it 'returns correct id for production' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        expect(presenter.tag_manager_id).to eq('GTM-K5L8F5XD')
      end
      it 'returns nil if production but GA4 id not present' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        allow(secrets).to receive(:google_analytics_4_id).and_return(nil)
        expect(presenter.tag_manager_id).to be_nil
      end
      it 'returns nil if production but institution is excluded' do
        allow(settings).to receive(:host).and_return('www.fulcrum.org')
        allow(mock_controller).to receive(:current_institutions).and_return([double('institution', identifier: '490')])
        expect(presenter.tag_manager_id).to be_nil
      end
    end
    it 'returns nil otherwise' do
      allow(settings).to receive(:host).and_return('other-host')
      expect(presenter.tag_manager_id).to be_nil
    end
  end

  describe '#hotjar_id?' do
    it 'returns true if preview' do
      allow(settings).to receive(:host).and_return('heliotrope-preview.hydra.lib.umich.edu')
      expect(presenter.hotjar_id?).to be true
    end
    it 'returns true if production' do
      allow(settings).to receive(:host).and_return('www.fulcrum.org')
      expect(presenter.hotjar_id?).to be true
    end
    it 'returns false otherwise' do
      allow(settings).to receive(:host).and_return('other-host')
      expect(presenter.hotjar_id?).to be false
    end
  end

  describe '#hotjar_id' do
    it 'returns correct id for preview' do
      allow(settings).to receive(:host).and_return('heliotrope-preview.hydra.lib.umich.edu')
      expect(presenter.hotjar_id).to eq('2858980')
    end
    it 'returns correct id for production' do
      allow(settings).to receive(:host).and_return('www.fulcrum.org')
      expect(presenter.hotjar_id).to eq('2863753')
    end
  end
end
