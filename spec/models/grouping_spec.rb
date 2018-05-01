# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping, type: :model do
  subject { grouping }

  let(:identifier) { 'identifier' }
  let(:lessee) { Lessee.find_by(identifier: identifier) }

  context 'build' do
    let(:grouping) { build(:grouping, identifier: identifier) }

    it { is_expected.to be_valid }

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
      before { grouping.save }

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
        before { grouping.destroy }

        it { expect(lessee).to be nil }
      end
    end
  end

  context 'create' do
    let(:grouping) { create(:grouping, identifier: identifier) }

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
      before { grouping.destroy }

      it { expect(lessee).to be nil }
    end
  end
end
