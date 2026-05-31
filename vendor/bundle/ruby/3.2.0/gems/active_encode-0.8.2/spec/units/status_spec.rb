# frozen_string_literal: true
require 'spec_helper'

describe ActiveEncode::Status do
  before do
    class CustomEncode < ActiveEncode::Base
    end
  end
  after do
    Object.send(:remove_const, :CustomEncode)
  end

  subject { encode_class.new(nil) }
  let(:encode_class) { ActiveEncode::Base }

  describe 'attributes' do
    it { is_expected.to respond_to(:state, :errors, :created_at, :updated_at) }

    context 'with an ActiveEncode::Base subclass' do
      let(:encode_class) { CustomEncode }

      it { is_expected.to respond_to(:state, :errors, :created_at, :updated_at) }
    end
  end

  context 'new object' do
    it { is_expected.not_to be_created }
    it { is_expected.not_to be_running }
    it { is_expected.not_to be_cancelled }
    it { is_expected.not_to be_completed }
    it { is_expected.not_to be_failed }
  end

  context 'running job' do
    before do
      subject.id = 1
      subject.state = :running
    end
    it { is_expected.to be_created }
    it { is_expected.to be_running }
    it { is_expected.not_to be_cancelled }
    it { is_expected.not_to be_completed }
    it { is_expected.not_to be_failed }
  end

  context 'cancelled job' do
    before do
      subject.id = 1
      subject.state = :cancelled
    end
    it { is_expected.to be_created }
    it { is_expected.not_to be_running }
    it { is_expected.to be_cancelled }
    it { is_expected.not_to be_completed }
    it { is_expected.not_to be_failed }
  end

  context 'completed job' do
    before do
      subject.id = 1
      subject.state = :completed
    end
    it { is_expected.to be_created }
    it { is_expected.not_to be_running }
    it { is_expected.not_to be_cancelled }
    it { is_expected.to be_completed }
    it { is_expected.not_to be_failed }
  end

  context 'failed job' do
    before do
      subject.id = 1
      subject.state = :failed
    end
    it { is_expected.to be_created }
    it { is_expected.not_to be_running }
    it { is_expected.not_to be_cancelled }
    it { is_expected.not_to be_completed }
    it { is_expected.to be_failed }
  end
end
