# frozen_string_literal: true
require 'spec_helper'

describe ActiveEncode::Callbacks do
  before do
    class CallbackEncode < ActiveEncode::Base
      after_find ->(encode) { encode.history << "CallbackEncode ran after_find" }

      after_reload ->(encode) { encode.history << "CallbackEncode ran after_reload" }

      before_create ->(encode) { encode.history << "CallbackEncode ran before_create" }
      after_create ->(encode) { encode.history << "CallbackEncode ran after_create" }

      before_cancel ->(encode) { encode.history << "CallbackEncode ran before_cancel" }
      after_cancel ->(encode) { encode.history << "CallbackEncode ran after_cancel" }

      around_create do |encode, block|
        encode.history << "CallbackEncode ran around_create_start"
        block.call
        encode.history << "CallbackEncode ran around_create_stop"
      end

      around_cancel do |encode, block|
        encode.history << "CallbackEncode ran around_cancel_start"
        block.call
        encode.history << "CallbackEncode ran around_cancel_stop"
      end

      def history
        @history ||= []
      end
    end
  end

  after do
    Object.send(:remove_const, :CallbackEncode)
  end

  describe 'find callback' do
    subject { CallbackEncode.find(encode.id).history }
    let(:encode) { CallbackEncode.create("sample.mp4") }
    it { is_expected.to include("CallbackEncode ran after_find") }
  end

  describe 'reload callback' do
    subject { encode.reload.history }
    let(:encode) { CallbackEncode.create("sample.mp4") }
    it { is_expected.to include("CallbackEncode ran after_reload") }
  end

  describe 'create callbacks' do
    subject { CallbackEncode.create("sample.mp4").history }
    it { is_expected.to include("CallbackEncode ran before_create") }
    it { is_expected.to include("CallbackEncode ran after_create") }
    it { is_expected.to include("CallbackEncode ran around_create_start") }
    it { is_expected.to include("CallbackEncode ran around_create_stop") }
  end

  describe 'cancel callbacks' do
    subject { CallbackEncode.create("sample.mp4").cancel!.history }
    it { is_expected.to include("CallbackEncode ran before_cancel") }
    it { is_expected.to include("CallbackEncode ran after_cancel") }
    it { is_expected.to include("CallbackEncode ran around_cancel_start") }
    it { is_expected.to include("CallbackEncode ran around_cancel_stop") }
  end
end
