# frozen_string_literal: true
shared_examples 'a persistence strategy' do
  shared_context 'with changes' do
    before do
      subject.source << 
        RDF::Statement.new(RDF::Node.new, RDF::Vocab::DC.title, 'moomin')
    end
  end

  describe '#persist!' do
    it 'evaluates true on success' do
      expect(subject.persist!).to be_truthy
    end

    context 'with changes' do
      include_context 'with changes'

      it 'evaluates true on success' do
        expect(subject.persist!).to be_truthy
      end
    end
  end
end
