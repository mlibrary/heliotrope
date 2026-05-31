# frozen_string_literal: true
require 'spec_helper'

describe ActiveEncode::GlobalID do
  before do
    class CustomEncode < ActiveEncode::Base
    end
  end

  after do
    Object.send(:remove_const, :CustomEncode)
  end

  describe '#to_global_id' do
    subject { encode.to_global_id }
    let(:encode_class) { ActiveEncode::Base }
    let(:encode) { encode_class.create(nil) }

    it { is_expected.to be_a GlobalID }
    it { expect(subject.model_class).to eq encode_class }
    it { expect(subject.model_id).to eq encode.id }
    it { expect(subject.app).to eq 'ActiveEncode' }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to be_a GlobalID }
      it { expect(subject.model_class).to eq encode_class }
      it { expect(subject.model_id).to eq encode.id }
      it { expect(subject.app).to eq 'ActiveEncode' }
    end
  end

  describe 'GlobalID::Locator#locate' do
    subject { GlobalID::Locator.locate(global_id) }
    let(:encode_class) { ActiveEncode::Base }
    let(:encode) { encode_class.create(nil) }
    let(:global_id) { encode.to_global_id }

    it { is_expected.to be_a encode_class }
    it { expect(subject.id).to eq encode.id }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to be_a encode_class }
      it { expect(subject.id).to eq encode.id }
    end
  end
end
