# frozen_string_literal: true

require 'rails_helper'

def object_ids
  ids = []
  ActiveFedora::Base.all.each do |obj|
    ids << obj.id
  end
  puts_objects(ids)
  ids
end

def ldp_gone_ids(ids)
  puts_objects(ids)
  gone_ids = []
  ids.each_with_index do |id, index|
    begin
      ActiveFedora::Base.find(id)
    rescue Ldp::Gone
      gone_ids << id
    rescue StandardError
    end
  end
  gone_ids
end

def puts_objects(ids)
  return # comment for debug puts
  ids.each_with_index do |id, index|
    begin
      obj = ActiveFedora::Base.find(id)
      puts "[#{index}] #{id} #{obj.inspect}"
    rescue ActiveFedora::ObjectNotFoundError
      puts "[#{index}] #{id} ActiveFedora::ObjectNotFoundError"
    rescue Ldp::Gone
      puts "[#{index}] #{id} Ldp::Gone"
    rescue ActiveFedora::ActiveFedoraError
      puts "[#{index}] #{id} ActiveFedora::ActiveFedoraError"
    rescue StandardError => e
      puts "[#{index}] #{id} #{e}"
    end
  end
  puts ''
end

RSpec.describe DestroyActiveFedoraObjectsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    subject(:job) { described_class.perform_later }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe '#perform_now' do
    context 'object not found error' do
      let(:noid) { 'validnoid' }
      let(:msg) { "DestroyActiveFedoraObjectsJob #{noid} ActiveFedora::ObjectNotFoundError" }

      before { allow(Rails.logger).to receive(:error).with(msg) }

      it 'logs error' do
        expect(ActiveFedora::Base.all.count).to eq(0)
        described_class.perform_now([noid])
        expect(Rails.logger).to have_received(:error).with(msg)
        expect(ActiveFedora::Base.all.count).to eq(0)
      end
    end

    context 'object gone' do
      let(:noid) { 'validnoid' }
      let(:base) { instance_double(ActiveFedora::Base, 'base') }
      let(:msg) { "DestroyActiveFedoraObjectsJob #{noid} Ldp::Gone" }

      before do
        allow(ActiveFedora::Base).to receive(:find).with(noid).and_raise(Ldp::Gone)
        allow(Rails.logger).to receive(:error).with(msg)
      end

      it 'logs error' do
        expect(ActiveFedora::Base.all.count).to eq(0)
        described_class.perform_now([noid])
        expect(Rails.logger).to have_received(:error).with(msg)
        expect(ActiveFedora::Base.all.count).to eq(0)
      end
    end

    context 'standard error' do
      let(:noid) { 'validnoid' }
      let(:base) { instance_double(ActiveFedora::Base, 'base') }
      let(:msg) { "DestroyActiveFedoraObjectsJob #{noid} StandardError #{error_msg}" }
      let(:error_msg) { 'Error Message' }

      before do
        allow(ActiveFedora::Base).to receive(:find).with(noid).and_raise(error_msg)
        allow(Rails.logger).to receive(:error).with(msg)
      end

      it 'logs error' do
        expect(ActiveFedora::Base.all.count).to eq(0)
        described_class.perform_now([noid])
        expect(Rails.logger).to have_received(:error).with(msg)
        expect(ActiveFedora::Base.all.count).to eq(0)
      end
    end

    context 'independent objects' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set) }

      it "destroys objects" do
        expect(ActiveFedora::Base.all.count).to eq(0)

        monograph
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(0)
        expect(ActiveFedora::Base.all.count).to eq(3)

        file_set
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(1)
        expect(ActiveFedora::Base.all.count).to eq(6)

        ids = object_ids
        expect(ids.count).to eq(6)

        described_class.perform_now([monograph.id, file_set.id])

        gone_ids = ldp_gone_ids(ids)
        expect(ids.count - gone_ids.count).to eq(0)
      end
    end

    context 'interdependent objects' do
      let(:monograph_with_file_set) do
        create(:monograph) do |m|
          m.ordered_members << monograph_file_set
          m.save
          monograph_file_set.save! # Force reindexing
          m
        end
      end
      let(:monograph_file_set) { create(:file_set) }

      it "deletes parent object and orphans child" do
        expect(ActiveFedora::Base.all.count).to eq(0)

        monograph_with_file_set
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(1)
        expect(ActiveFedora::Base.all.count).to eq(9)

        ids = object_ids
        expect(ids.count).to eq(9)

        described_class.perform_now([monograph_with_file_set.id])

        gone_ids = ldp_gone_ids(ids)
        expect(ids.count - gone_ids.count).to eq(3)
      end

      it "deletes child object" do
        expect(ActiveFedora::Base.all.count).to eq(0)

        monograph_with_file_set
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(1)
        expect(ActiveFedora::Base.all.count).to eq(9)

        ids = object_ids
        expect(ids.count).to eq(9)

        described_class.perform_now([monograph_file_set.id])

        gone_ids = ldp_gone_ids(ids)
        expect(ids.count - gone_ids.count).to eq(5)
      end

      it "deletes child and parent object" do
        expect(ActiveFedora::Base.all.count).to eq(0)

        monograph_with_file_set
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(1)
        expect(ActiveFedora::Base.all.count).to eq(9)

        ids = object_ids
        expect(ids.count).to eq(9)

        described_class.perform_now([monograph_file_set.id, monograph_with_file_set.id])

        gone_ids = ldp_gone_ids(ids)
        expect(ids.count - gone_ids.count).to eq(0)
      end

      it "deletes parent and child object" do
        expect(ActiveFedora::Base.all.count).to eq(0)

        monograph_with_file_set
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(1)
        expect(ActiveFedora::Base.all.count).to eq(9)

        ids = object_ids
        expect(ids.count).to eq(9)

        described_class.perform_now([monograph_with_file_set.id, monograph_file_set.id])

        gone_ids = ldp_gone_ids(ids)
        expect(ids.count - gone_ids.count).to eq(0)
      end
    end
  end
end
