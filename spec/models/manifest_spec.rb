# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Manifest, type: :model do
  let(:monograph) { create(:monograph) }
  let(:current_user) { double("current user") }

  # NOTE: #create is dependent on Carrierwave and was not tested.

  before do
    allow($stdout).to receive(:puts) # Don't print status messages during specs
  end

  it 'no csv file' do
    implicit = described_class.from_monograph(monograph.id)
    expect(implicit.id).to eq monograph.id
    expect(implicit.persisted?).to be false
    expect(implicit.filename).to be nil

    explicit = described_class.from_monograph_manifest(monograph.id)
    expect(explicit.id).to eq monograph.id
    expect(explicit.persisted?).to be false
    expect(explicit.filename).to be nil

    expect(implicit == explicit).to be false
  end

  it 'csv file' do
    implicit = described_class.from_monograph(monograph.id)

    file_dir = implicit.csv.store_dir
    FileUtils.mkdir_p(file_dir) unless Dir.exist?(file_dir)
    FileUtils.rm_rf(Dir.glob("#{file_dir}/*"))
    file_name = "#{monograph.id}.csv"
    file_path = File.join(file_dir, file_name)
    file = File.new(file_path, "w")
    exporter = Export::Exporter.new(monograph.id)
    file.write(exporter.export)
    file.close

    expect(implicit.persisted?).to be true
    expect(implicit.filename).to eq file_name

    explicit = described_class.from_monograph_manifest(monograph.id)

    expect(explicit.persisted?).to be true
    expect(explicit.filename).to eq file_name

    expect(implicit == explicit).to be true

    expect(explicit.table_rows.count).to eq 1
    expect(explicit.table_rows[0].count).to eq 4
    expect(explicit.table_rows[0][3]["title"].first).to eq monograph.title.first

    explicit.table_rows[0][3]["title"] = ["NEW TITLE"]

    expect(implicit == explicit).to be false

    explicit.destroy(current_user)

    expect(implicit.id).to eq monograph.id
    expect(implicit.persisted?).to be false
    expect(implicit.filename).to be nil

    expect(explicit.id).to eq monograph.id
    expect(explicit.persisted?).to be false
    expect(explicit.filename).to be nil
  end
end
