# frozen_string_literal: true
require 'spec_helper'

describe ActiveEncode::Core do
  before do
    class CustomEncode < ActiveEncode::Base
    end
  end
  after do
    Object.send(:remove_const, :CustomEncode)
  end

  let(:encode_class) { ActiveEncode::Base }

  describe 'attributes' do
    subject { encode_class.new(nil) }

    it { is_expected.to respond_to(:id, :input, :output, :options, :percent_complete, :current_operations) }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to respond_to(:id, :input, :output, :options, :percent_complete, :current_operations) }
    end
  end

  describe 'find' do
    subject { encode_class.find(id) }
    let(:id) { encode_class.create(nil).id }

    it { is_expected.to be_a encode_class }
    it { expect(subject.id).to eq id }

    context 'with no id' do
      let(:id) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to be_a encode_class }
      it { expect(subject.id).to eq id }

      context 'casting' do
        let(:id) { ActiveEncode::Base.create(nil).id }

        it { is_expected.to be_a encode_class }
        it { expect(subject.id).to eq id }
      end
    end
  end

  describe 'create' do
    subject { encode_class.create(nil) }

    it { is_expected.to be_a encode_class }
    it { expect(subject.id).not_to be nil }
    it { expect(subject.state).not_to be nil }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to be_a encode_class }
      it { expect(subject.id).not_to be nil }
      it { expect(subject.state).not_to be nil }
    end
  end

  describe '#create!' do
    subject { encode.create! }
    let(:encode) { encode_class.new(nil) }

    it { is_expected.to equal encode }
    it { is_expected.to be_a encode_class }
    it { expect(subject.id).not_to be nil }
    it { expect(subject.state).not_to be nil }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to equal encode }
      it { is_expected.to be_a encode_class }
      it { expect(subject.id).not_to be nil }
      it { expect(subject.state).not_to be nil }
    end
  end

  describe '#cancel!' do
    subject { encode.cancel! }
    let(:encode) { encode_class.create(nil) }

    it { is_expected.to equal encode }
    it { is_expected.to be_a encode_class }
    it { expect(subject.id).not_to be nil }
    it { is_expected.to be_cancelled }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to equal encode }
      it { is_expected.to be_a encode_class }
      it { expect(subject.id).not_to be nil }
      it { is_expected.to be_cancelled }
    end
  end

  describe '#reload' do
    subject { encode.reload }
    let(:encode) { encode_class.create(nil) }

    it { is_expected.to equal encode }
    it { is_expected.to be_a encode_class }
    it { expect(subject.id).not_to be nil }
    it { expect(subject.state).not_to be nil }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to equal encode }
      it { is_expected.to be_a encode_class }
      it { expect(subject.id).not_to be nil }
      it { expect(subject.state).not_to be nil }
    end
  end

  describe '#new' do
    before do
      class DefaultOptionsEncode < ActiveEncode::Base
        def self.default_options(_input_url)
          { preset: 'video' }
        end
      end
    end
    after do
      Object.send(:remove_const, :DefaultOptionsEncode)
    end

    subject { encode.options }
    let(:encode_class) { DefaultOptionsEncode }
    let(:default_options) { { preset: 'video' } }
    let(:options) { { output: [{ label: 'high', ffmpeg_opt: "640x480" }] } }
    let(:encode) { encode_class.new(nil, options) }

    it 'merges default options and options parameter' do
      expect(subject).to include default_options
      expect(subject).to include options
    end

    context 'with collisions' do
      let(:options) { { preset: 'avalon' } }
      it 'prefers options parameter' do
        expect(subject[:preset]).to eq 'avalon'
      end
    end
  end
end
