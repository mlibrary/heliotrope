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

  describe '#publisher_ids' do
    let!(:publisher1) { create(:press) }
    let!(:publisher2) { create(:press) }
    subject { described_class.new(current_user).publisher_ids }
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

  describe '#user_ids' do
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
