# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Press, type: :model do
  describe 'validation' do
    let(:press) { described_class.new }

    it 'must have a subdomain' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:subdomain]).to eq ["can't be blank"]
    end

    it 'must have a name' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:name]).to eq ["can't be blank"]
    end

    it 'must have a logo' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:logo_path]).to eq ["You must upload a logo image"]
    end

    it 'must have a description' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:description]).to eq ["can't be blank"]
    end

    it 'must have a valid press_url' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:press_url]).to eq ["can't be blank", "is invalid"]
    end

    it 'must have a google_analytics' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:google_analytics]).to eq ["can't be blank"]
    end
  end

  let(:press) { build(:press) }

  describe "to_param" do
    subject { press.to_param }
    let(:press) { build(:press, subdomain: 'umich') }

    it { is_expected.to eq 'umich' }
  end

  describe "roles" do
    subject { press.roles }
    it { is_expected.to eq [] }
  end
end
