# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe Rake::Task, "heliotrope:purge_world_counter_events" do
  let(:task) { described_class["heliotrope:purge_world_counter_events"] }
  let(:output) { StringIO.new }
  let!(:investigation) { create(:counter_report, institution: 0, investigation: 1, request: nil) }
  let!(:search) { create(:counter_report, institution: 0, investigation: nil, request: nil, search: 1) }
  let!(:both) { create(:counter_report, institution: 0, investigation: 1, request: nil, search: 1) }
  let!(:download) { create(:counter_report, institution: 0, investigation: 1, request: 1) }
  let!(:zero_request) { create(:counter_report, institution: 0, investigation: 1, request: 0) }
  let!(:identified_investigation) { create(:counter_report, institution: 1, investigation: 1, request: nil) }
  let!(:identified_search) { create(:counter_report, institution: 1, investigation: nil, search: 1) }
  let!(:other) { create(:counter_report, institution: 0, investigation: nil, request: nil) }

  around do |example|
    original_application = Rake.application
    original_stdout = $stdout
    $stdout = output
    Rake.application = Rake::Application.new
    described_class.define_task(:environment)
    load Rails.root.join("lib", "tasks", "counter_reports", "purge_world_events.rake")
    example.run
  ensure
    Rake.application = original_application
    $stdout = original_stdout
  end

  before do
    allow(Kernel).to receive(:sleep)
  end

  it "previews exact matching rows without deleting by default" do
    expect { task.invoke }.not_to change(CounterReport, :count)
    expect(output.string).to match(/Finished dry run:.*matched=3/)
  end

  it "deletes only matching rows in bounded, throttled batches" do
    expect { task.invoke("2", "0.1", "0", "true") }.to change(CounterReport, :count).by(-3)

    expect(CounterReport.where(id: [investigation.id, search.id, both.id])).to be_empty
    expect(CounterReport.where(id: [download.id, zero_request.id, identified_investigation.id, identified_search.id, other.id]).count).to eq 5
    expect(Kernel).to have_received(:sleep).with(0.1).exactly(4).times
    expect(output.string).to match(/Finished deleting:.*deleted=3/)
  end

  it "can resume after the last completed primary key" do
    expect { task.invoke("2", "0.1", search.id.to_s, "true") }.to change(CounterReport, :count).by(-1)

    expect(CounterReport.exists?(investigation.id)).to be true
    expect(CounterReport.exists?(search.id)).to be true
    expect(CounterReport.exists?(both.id)).to be false
  end

  it "does not chase new records inserted during the purge" do
    new_search = nil
    allow(Kernel).to receive(:sleep) do
      new_search ||= create(:counter_report, institution: 0, investigation: nil, search: 1)
    end

    task.invoke("2", "0.1", "0", "true")

    expect(CounterReport.exists?(new_search.id)).to be true
    expect(Kernel).to have_received(:sleep).exactly(4).times
  end

  it "rejects unsafe batch sizes before deleting" do
    expect { task.invoke("1001", "0.1", "0", "true") }.to raise_error(ArgumentError, /batch_size/)
    expect(CounterReport.exists?(investigation.id)).to be true
  end

  it "rejects an unthrottled run" do
    expect { task.invoke("500", "0", "0", "true") }.to raise_error(ArgumentError, /pause_seconds/)
  end

  it "requires an explicit boolean deletion argument" do
    expect { task.invoke("500", "0.1", "0", "yes") }.to raise_error(ArgumentError, /delete/)
  end

  it "refuses to run on a table engine that takes table-level write locks" do
    allow(CounterReport.connection).to receive(:select_value).and_call_original
    allow(CounterReport.connection).to receive(:select_value).with(
      "SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'counter_reports'"
    ).and_return("MyISAM")

    expect { task.invoke("500", "0.1", "0", "true") }.to raise_error(RuntimeError, /must use InnoDB/)
    expect(CounterReport.exists?(investigation.id)).to be true
  end
end
