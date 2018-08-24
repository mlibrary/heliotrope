# frozen_string_literal: true

require 'rails_helper'

describe RepositoryPresenter do
  let(:current_user) { double("current_user") }

  context 'heredity' do
    it { expect(described_class.new(nil)).to be_a ApplicationPresenter }
  end

  describe '#initialize' do
    subject { described_class.new(current_user) }

    it { expect(subject.current_user).to eq current_user }
  end

  describe '#product_ids' do
    subject { described_class.new(current_user).product_ids }

    let!(:product1) { create(:product, identifier: 'product1') }
    let!(:product2) { create(:product, identifier: 'product2') }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(product1.id, product2.id)
    end
  end

  describe '#component_ids' do
    subject { described_class.new(current_user).component_ids }

    let!(:component1) { create(:component, handle: 'component1') }
    let!(:component2) { create(:component, handle: 'component2') }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(component1.id, component2.id)
    end
  end

  describe '#lessee_ids' do
    subject { described_class.new(current_user).lessee_ids }

    let!(:lessee1) { create(:lessee, identifier: 'lessee1') }
    let!(:lessee2) { create(:lessee, identifier: 'lessee2') }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(lessee1.id, lessee2.id)
    end
  end

  describe '#institution_ids' do
    subject { described_class.new(current_user).institution_ids }

    let!(:institution1) { create(:institution, identifier: 'institution1') }
    let!(:institution2) { create(:institution, identifier: 'institution2') }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(institution1.id, institution2.id)
    end
  end

  describe '#grouping_ids' do
    subject { described_class.new(current_user).grouping_ids }

    let!(:grouping1) { create(:grouping, identifier: 'grouping1') }
    let!(:grouping2) { create(:grouping, identifier: 'grouping2') }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(grouping1.id, grouping2.id)
    end
  end

  describe '#publisher_ids' do
    subject { described_class.new(current_user).publisher_ids }

    let!(:publisher1) { create(:press) }
    let!(:publisher2) { create(:press) }

    it do
      expect(subject).to be_a Array
      expect(subject.length).to eq 2
      expect(subject).to include(publisher1.id, publisher2.id)
    end
  end

  describe '#monograph_ids' do
    let!(:publisher1) { create(:press) }
    let!(:publisher2) { create(:press) }
    let!(:monograph1) { create(:monograph, press: publisher1.subdomain) }
    let!(:monograph2) { create(:monograph, press: publisher2.subdomain) }

    context 'nil publisher' do
      subject { described_class.new(current_user).monograph_ids }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 2
        expect(subject).to include(monograph1.id, monograph2.id)
      end
    end

    context 'first publisher' do
      subject { described_class.new(current_user).monograph_ids(publisher1) }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 1
        expect(subject).to include(monograph1.id)
      end
    end

    context 'second publisher' do
      subject { described_class.new(current_user).monograph_ids(publisher2) }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 1
        expect(subject).to include(monograph2.id)
      end
    end
  end

  describe '#asset_ids' do
    let!(:publisher1) { create(:press) }
    let!(:publisher2) { create(:press) }
    let!(:monograph1) { create(:monograph, press: publisher1.subdomain) }
    let!(:monograph2) { create(:monograph, press: publisher2.subdomain) }

    context 'when monographs have no assets' do
      subject { described_class.new(current_user).asset_ids }

      it { expect(subject.length).to eq 0 }
    end

    context 'when monographs have assets' do
      let!(:asset1) { create(:file_set) }
      let!(:asset2) { create(:file_set) }

      before do
        monograph1.ordered_members << asset1
        monograph1.save!
        monograph2.ordered_members << asset2
        monograph2.save!
      end

      context 'nil publisher' do
        subject { described_class.new(current_user).asset_ids }

        it do
          expect(subject).to be_a Array
          expect(subject.length).to eq 2
          expect(subject).to include(asset1.id, asset2.id)
        end
      end

      context 'first publisher' do
        subject { described_class.new(current_user).asset_ids(publisher1) }

        it do
          expect(subject).to be_a Array
          expect(subject.length).to eq 1
          expect(subject).to include(asset1.id)
        end
      end

      context 'second publisher' do
        subject { described_class.new(current_user).asset_ids(publisher2) }

        it do
          expect(subject).to be_a Array
          expect(subject.length).to eq 1
          expect(subject).to include(asset2.id)
        end
      end
    end
  end

  describe '#user_ids' do
    before do
      User.destroy_all
    end

    let!(:publisher1) { create(:press) }
    let!(:publisher2) { create(:press) }
    let!(:user1) { create(:press_admin, press: publisher1) }
    let!(:user2) { create(:press_admin, press: publisher2) }

    context 'nil publisher' do
      subject { described_class.new(current_user).user_ids }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 2
        expect(subject).to include(user1.id, user2.id)
      end
    end

    context 'first publisher' do
      subject { described_class.new(current_user).user_ids(publisher1) }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 1
        expect(subject).to include(user1.id)
      end
    end

    context 'second publisher' do
      subject { described_class.new(current_user).user_ids(publisher2) }

      it do
        expect(subject).to be_a Array
        expect(subject.length).to eq 1
        expect(subject).to include(user2.id)
      end
    end
  end
end
