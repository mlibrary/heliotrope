# frozen_string_literal: true
require 'rails_helper'

describe ActiveEncode::Persistence, db_clean: true do
  before do
    class CustomEncode < ActiveEncode::Base
      include ActiveEncode::Persistence
    end
  end

  after do
    Object.send(:remove_const, :CustomEncode)
  end

  describe 'find' do
    subject { ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s) }
    let(:encode) { CustomEncode.create(nil) }

    it 'persists changes on find' do
      expect { CustomEncode.find(encode.id) }.to change { subject.reload.updated_at }
    end
  end

  describe 'create' do
    subject { ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s) }
    let(:create_options) { { option: 'value' } }
    let(:encode) { CustomEncode.create(nil, create_options) }

    it 'creates a record' do
      expect { encode }.to change { ActiveEncode::EncodeRecord.count }.by(1)
    end

    it { expect(subject.global_id).to eq encode.to_global_id.to_s }
    it { expect(subject.state).to eq encode.state.to_s }
    it { expect(subject.adapter).to eq encode.class.engine_adapter.class.name }
    it { expect(subject.title).to eq encode.input.url.to_s }
    it { expect(subject.raw_object).to eq encode.to_json }
    it { expect(subject.created_at).to be_within(1.second).of encode.created_at }
    it { expect(subject.updated_at).to be_within(1.second).of encode.updated_at }
    it { expect(subject.create_options).to eq create_options.to_json }
    it { expect(subject.progress).to eq encode.percent_complete }
  end

  describe 'cancel' do
    subject { ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s) }
    let(:encode) { CustomEncode.create(nil) }

    it 'persists changes on cancel' do
      expect { encode.cancel! }.to change { subject.reload.state }.from("running").to("cancelled")
    end
  end

  describe 'reload' do
    subject { ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s) }
    let(:encode) { CustomEncode.create(nil) }

    it 'persists changes on reload' do
      expect { encode.reload }.to change { subject.reload.updated_at }
    end
  end
end
