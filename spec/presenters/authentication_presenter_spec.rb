# frozen_string_literal: true

require 'rails_helper'

describe AuthenticationPresenter do
  subject { presenter }

  let(:presenter) { described_class.for(actor, subdomain, id, filter) }
  let(:actor) { Anonymous.new({}) }
  let(:subdomain) { }
  let(:id) { }
  let(:filter) { }

  it { is_expected.to be_an_instance_of(described_class) }

  describe '#page_title' do
    subject { presenter.page_title }

    it { is_expected.to eq 'Authentication' }
  end

  describe '#page_class' do
    subject { presenter.page_class }

    it { is_expected.to eq 'press' }
  end

  describe '#subdomain' do
    subject { presenter.subdomain }

    let(:auth) { instance_double(Auth, 'auth', publisher_subdomain: publisher_subdomain) }
    let(:publisher_subdomain) { 'subdomain' }

    before { allow(Auth).to receive(:new).and_return(auth) }

    it { is_expected.to be publisher_subdomain }
  end

  describe '#institutions' do
    subject { presenter.institutions }

    let(:auth) { instance_double(Auth, 'auth',
                                 monograph_subscribing_institutions: monograph_subscribing_institutions,
                                 publisher_subscribing_institutions: publisher_subscribing_institutions) }
    let(:monograph_subscribing_institutions) { ['monograph'] }
    let(:publisher_subscribing_institutions) { ['monograph', 'publisher'] }

    before { allow(Auth).to receive(:new).and_return(auth) }

    it { is_expected.to be publisher_subscribing_institutions }

    context 'when filter' do
      let(:filter) { true }

      it { is_expected.to be monograph_subscribing_institutions }
    end
  end

  describe '#monograph_other_options?' do
    subject { presenter.monograph_other_options? }

    let(:auth) { instance_double(Auth, 'auth',
                                 monograph?: monograph,
                                 monograph_buy_url?: monograph_buy_url,
                                 monograph_worldcat_url?: monograph_worldcat_url) }
    let(:monograph) { true }
    let(:monograph_buy_url) { true }
    let(:monograph_worldcat_url) { true }

    before { allow(Auth).to receive(:new).and_return(auth) }

    it { is_expected.to be true }

    context 'when no monograph' do
      let(:monograph) { false }

      it { is_expected.to be false }
    end

    context 'when no buy url' do
      let(:monograph_buy_url) { false }

      it { is_expected.to be true }

      context 'when no worldcat url' do
        let(:monograph_worldcat_url) { false }

        it { is_expected.to be false }
      end
    end

    context 'when no worldcat url' do
      let(:monograph_worldcat_url) { false }

      it { is_expected.to be true }

      context 'when no buy url' do
        let(:monograph_buy_url) { false }

        it { is_expected.to be false }
      end
    end
  end
end
