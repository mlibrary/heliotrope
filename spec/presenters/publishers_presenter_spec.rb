# frozen_string_literal: true

require 'rails_helper'

describe PublishersPresenter do
  let(:current_user) { double("current_user") }

  context 'heredity' do
    it { expect(described_class.new(nil)).to be_a ApplicationPresenter }
  end

  describe '#initialize' do
    subject { described_class.new(current_user) }
    it { expect(subject.current_user).to eq current_user }
  end

  describe '#all' do
    subject { described_class.new(current_user).all }
    context 'verify dependencies' do
      it { expect(Press).to respond_to(:all) }
      it { expect(Press.new).to respond_to(:subdomain) }
    end
    context 'without publishers' do
      before { allow(Press).to receive(:all).and_return([]) }
      it do
        expect(subject).to be_a Array
        expect(subject).to be_empty
      end
    end
    context 'with publisher' do
      let(:publisher) { double("publisher") }
      before { allow(Press).to receive(:all).and_return([publisher]) }
      it do
        expect(subject).to be_a Array
        expect(subject).to_not be_empty
        expect(subject[0]).to be_a PublisherPresenter
        expect(subject[0].publisher).to eq publisher
        expect(subject[0].current_user).to eq current_user
      end
    end
    context 'with publishers sorted on name' do
      let(:publisher1) { double("publisher1") }
      let(:publisher2) { double("publisher2") }
      before do
        allow(Press).to receive(:all).and_return([publisher1, publisher2])
        allow(publisher1).to receive(:name).and_return("z")
        allow(publisher2).to receive(:name).and_return("a")
      end
      it do
        expect(subject).to be_a Array
        expect(subject).to_not be_empty
        expect(subject[0]).to be_a PublisherPresenter
        expect(subject[0].publisher).to eq publisher2
        expect(subject[0].current_user).to eq current_user
        expect(subject[1]).to be_a PublisherPresenter
        expect(subject[1].publisher).to eq publisher1
        expect(subject[1].current_user).to eq current_user
      end
    end
  end
end
