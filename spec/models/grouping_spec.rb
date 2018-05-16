# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping, type: :model do
  let(:identifier) { 'identifier' }
  let(:lessee) { Lessee.find_by(identifier: identifier) }

  context 'build' do
    subject { build(:grouping, identifier: identifier) }

    it do
      is_expected.to be_valid
      expect(subject.update?).to be false
      expect(subject.destroy?).to be true
    end

    describe '#lessee?' do
      it { expect(subject.lessee?).to be false }
    end

    describe '#lessee' do
      it do
        expect(subject.lessee).to be nil
        expect(lessee).to be nil
      end
    end

    context 'saved' do
      before { subject.save }

      it { is_expected.to be_valid }

      describe '#lessee?' do
        it { expect(subject.lessee?).to be true }
      end

      describe '#lessee' do
        it do
          expect(subject.lessee).not_to be nil
          expect(subject.lessee).to eq lessee
        end
      end

      context 'destroy' do
        before { subject.destroy }

        it { expect(lessee).to be nil }
      end
    end
  end

  context 'create' do
    subject { create(:grouping, identifier: identifier) }

    it do
      is_expected.to be_valid
      expect(subject.update?).to be false
      expect(subject.destroy?).to be true
    end

    describe '#lessee?' do
      it { expect(subject.lessee?).to be true }
    end

    describe '#lessee' do
      it do
        expect(subject.lessee).not_to be nil
        expect(subject.lessee).to eq lessee
      end
    end

    context 'destroy' do
      before { subject.destroy }

      it { expect(lessee).to be nil }
    end

    it 'lessees and not_lessees' do
      n = 3
      lessees = []
      n.times { |i| lessees << create(:lessee, identifier: "lessee#{i}") }
      expected_lessees = []

      lessees.each_with_index do |lessee, index|
        expect(subject.lessees.count).to eq(index)
        expect(subject.not_lessees.count).to eq(n - index)
        expect(subject.lessees).to eq(expected_lessees)
        expected_lessees << lessee
        subject.lessees << lessee
        subject.save!
      end

      lessees.each_with_index do |lessee, index|
        expect(subject.lessees.count).to eq(n - index)
        expect(subject.not_lessees.count).to eq(index)
        expect(subject.lessees).to eq(expected_lessees)
        expected_lessees.delete(lessee)
        subject.lessees.delete(lessee)
        subject.save!
      end
    end

    it 'grouping_lessees and not_lessees' do
      n = 3
      lessees = []
      n.times { |i| lessees << create(:lessee, identifier: "lessee#{i}") }
      groupings = []
      n.times { |i| groupings << create(:grouping, identifier: "grouping#{i}") }
      grouping_lessees = []
      n.times { |i| grouping_lessees << groupings[i].lessee }
      expected_lessees = []

      grouping_lessees.each_with_index do |grouping_lessee, index|
        expect(subject.lessees.count).to eq(index)
        expect(subject.not_lessees.count).to eq(n - index)
        expect(subject.lessees).to eq(expected_lessees)
        expected_lessees << lessees[index]
        subject.lessees << lessees[index]
        subject.lessees << grouping_lessee
        subject.save!
      end

      lessees.each_with_index do |lessee, index|
        expect(subject.lessees.count).to eq(n - index)
        expect(subject.not_lessees.count).to eq(index)
        expect(subject.lessees).to eq(expected_lessees)
        expected_lessees.delete(lessee)
        subject.lessees.delete(lessee)
        subject.save!
      end
    end
  end
end
