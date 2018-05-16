# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateMonographJob, type: :job do
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:monograph) { create(:monograph, user: user, visibility: visibility) }
  let(:monograph_manifest) { MonographManifest.new(monograph.id) }

  before do
    allow($stdout).to receive(:puts) # Don't print status messages during specs
    stub_out_redis # Travis CI can't handle jobs
  end

  it "updates the monograph" do
    #
    # Create expected by modifying the original
    #
    original = Export::Exporter.new(monograph.id).export
    csv_table = CSV.parse(original, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
    csv_table[1]["Title"] = "UPDATED MONOGRAPH TITLE"
    expected = csv_table.to_csv

    expect(monograph_manifest.implicit.persisted?).to be false

    #
    # Create monograph_manifest.explicit by creating Carrierwave directory
    #
    file_dir = monograph_manifest.implicit.path
    FileUtils.mkdir_p(file_dir) unless Dir.exist?(file_dir)
    FileUtils.rm_rf(Dir.glob("#{file_dir}/*"))
    file_name = "#{monograph.id}.csv"
    file_path = File.join(file_dir, file_name)
    file = File.new(file_path, "w")
    file.write(expected)
    file.close

    expect(monograph_manifest.implicit.persisted?).to be true

    #
    # Perform the job
    #
    described_class.perform_now(user, monograph.id)
    updated = Export::Exporter.new(monograph.id).export
    expect(updated).not_to match original
    expect(updated).to match expected

    expect(monograph_manifest.implicit.persisted?).to be false
  end
end
