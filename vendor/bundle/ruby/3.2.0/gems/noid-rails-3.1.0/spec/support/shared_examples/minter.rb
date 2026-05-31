# frozen_string_literal: true

shared_examples 'a minter' do
  describe '#mint' do
    subject { minter.mint }

    it { is_expected.not_to be_empty }

    it 'does not mint the same ID twice in a row' do
      expect(subject).not_to eq described_class.new.mint
    end

    it 'is valid' do
      expect(minter.valid?(subject)).to be true
      expect(described_class.new.valid?(subject)).to be true
    end

    context 'with a different template' do
      it 'is invalid' do
        expect(described_class.new('.reedddk').valid?(subject)).to be false
      end
    end
  end

  context 'when the id already exists' do
    let(:existing_id) { 'ef12ef12f' }
    let(:unique_id) { 'bb22bb22b' }

    before do
      expect(subject).to receive(:next_id).and_return(existing_id, unique_id)
      allow(subject).to receive(:identifier_in_use?).with(existing_id).and_return(true)
      allow(subject).to receive(:identifier_in_use?).with(unique_id).and_return(false)
    end

    it 'skips the existing id' do
      expect(subject.mint).to eq unique_id
    end
  end
end
