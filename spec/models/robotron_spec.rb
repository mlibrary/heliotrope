# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robotron, type: :model do
  context 'Factory Bot' do
    subject(:robotron) { create(:robotron) }

    it do
      expect(robotron.valid?).to be true
    end
  end

  context 'Validation' do
    subject { described_class.new(ip: ip) }

    context 'blank ip' do
      let(:ip) { nil }

      it 'validates presence' do
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Ip can't be blank")
      end
    end

    context 'unique ip' do
      let(:ip) { 'ip' }

      it 'validates presence' do
        expect(subject.valid?).to be true
        expect(subject.errors).to be_empty
      end
    end

    context 'duplicate ip' do
      let(:ip) { 'ip' }

      it 'validates uniqueness' do
        create(:robotron, ip: ip)
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Ip has already been taken")
      end
    end
  end
end
