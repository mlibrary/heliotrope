# frozen_string_literal: true
require 'rails_helper'

describe ActiveEncode::Polling do
  before do
    class PollingEncode < ActiveEncode::Base
      include ActiveEncode::Polling
    end
  end

  after do
    Object.send(:remove_const, :PollingEncode)
  end

  describe 'after_create' do
    subject { PollingEncode.create("sample.mp4") }

    it "enqueues a PollingJob" do
      subject
      expect(ActiveEncode::PollingJob).to have_been_enqueued.with(subject)
    end
  end
end
