# frozen_string_literal: true
shared_examples_for "an ActiveModel" do
  subject { am_lint_class.new }

  describe '#to_key' do
    it 'should respond' do
      expect(subject).to respond_to :to_key
    end

    it 'should return an array of keys ' do
      def subject.persisted?() false end
      expect(subject.to_key).to contain_exactly(subject.id)
    end
  end

  describe '#to_param' do
    it 'should respond' do
      expect(subject).to respond_to :to_param
    end

    it 'should return nil when #persisted? is false ' do
      def subject.persisted?() false end
      expect(subject.to_param).to eq nil
    end
  end

  describe '#model_name' do
    let(:model_name) { subject.class.model_name }

    it 'should have a model name' do
      expect(model_name).to respond_to :to_str
    end

    it 'should have a human name' do
      expect(model_name.human).to respond_to :to_str
    end

    it 'should have a singular name' do
      expect(model_name.singular).to respond_to :to_str
    end

    it 'should have a plural name' do
      expect(model_name.plural).to respond_to :to_str
    end
  end

  describe '#to_partial_path' do
    it 'should return a string' do
      expect(subject.to_partial_path).to be_a String
    end
  end

  describe '#persisted?' do
    it 'should return a boolean' do
      expect(match_boolean(subject.persisted?)).to be true
    end
  end

  describe '#valid?' do
    it 'should return a boolean' do
      expect(match_boolean(subject.valid?)).to be true
    end
  end

  describe '#new_record' do
    it 'should return a boolean' do
      expect(match_boolean(subject.new_record?)).to be true
    end
  end

  describe '#destroyed?' do
    it 'should return a boolean' do
      expect(match_boolean(subject.destroyed?)).to be true
    end
  end

  private

    def match_boolean(result)
      result == true || result == false
    end
end
