# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Institution, type: :model do
  let(:identifier) { 'identifier' }

  describe 'lessee? and lessee' do
    let(:lessee) { Lessee.find_by(identifier: identifier) }

    context 'build' do
      subject { build(:institution, identifier: identifier) }

      it do
        is_expected.to be_valid
        expect(subject.update?).to be true
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

        it do
          is_expected.to be_valid
          expect(subject.update?).to be true
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
      end
    end

    context 'create' do
      subject { create(:institution, identifier: identifier) }

      it do
        is_expected.to be_valid
        expect(subject.update?).to be true
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
    end
  end

  describe '#shibboleth?' do
    subject { institution.shibboleth? }

    let(:institution) { build(:institution, identifier: identifier, entity_id: entity_id) }

    context 'nil' do
      let(:entity_id) { nil }

      it { is_expected.to be false }
    end

    context 'entity' do
      let(:entity_id) { "entity_id" }

      it { is_expected.to be true }
    end
  end
end
