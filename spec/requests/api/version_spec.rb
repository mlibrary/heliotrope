# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::Version, type: :request do
  let(:default_version) { described_class.new('constraint_version', true).matches?(request) }
  let(:version) { described_class.new('constraint_version').matches?(request) }
  let(:request) { double('request', headers: headers) }

  context 'missing request accept header' do
    let(:headers) { {} }

    it { expect(default_version).to be true }
    it { expect(version).to be false }
  end

  context 'empty request accept header' do
    let(:headers) { { accept: "" } }

    it { expect(default_version).to be true }
    it { expect(version).to be false }
  end

  context 'application/json request accept header' do
    let(:headers) { { accept: "application/json" } }

    it { expect(default_version).to be true }
    it { expect(version).to be false }
  end

  context 'requested request accept header' do
    let(:headers) { { accept: "application/json, application/vnd.heliotrope.#{requested_version}+json" } }

    context 'requested version equal to constraint version' do
      let(:requested_version) { 'constraint_version' }

      it { expect(default_version).to be true }
      it { expect(version).to be true }
    end

    context 'requested version not equal to constraint version' do
      let(:requested_version) { 'requested_version' }

      it { expect(default_version).to be false }
      it { expect(version).to be false }
    end
  end
end
