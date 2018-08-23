# frozen_string_literal: true

require 'rails_helper'

describe PublisherPresenter do
  let(:current_user) { double("current_user") }
  let(:publisher) { double("publisher") }

  context 'heredity' do
    it { expect(described_class.new(nil, nil)).to be_a ApplicationPresenter }
  end

  describe '#initialize' do
    subject { described_class.new(current_user, publisher) }

    it do
      expect(subject.current_user).to eq current_user
      expect(subject.publisher).to eq publisher
    end
  end

  describe 'delegate' do
    subject { described_class.new(current_user, publisher) }

    context 'verify dependencies' do
      it { expect(Press.new).to respond_to(:id) }
      it { expect(Press.new).to respond_to(:name) }
      it { expect(Press.new).to respond_to(:subdomain) }
    end

    context 'verify methods are delegated to publisher' do
      before do
        allow(publisher).to receive(:id).and_return(:id)
        allow(publisher).to receive(:name).and_return(:name)
        allow(publisher).to receive(:subdomain).and_return(:subdomain)
      end

      it do
        expect(subject.id).to equal :id
        expect(subject.name).to equal :name
        expect(subject.subdomain).to equal :subdomain
      end
    end
  end
end
