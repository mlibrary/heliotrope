# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe UnpackService do
  let(:noid) { '123456789' }
  let(:kind) { 'epub' }

  describe "#root_path_from_noid" do
    it { expect(described_class.root_path_from_noid(noid, kind)).to match(/\/12\/34\/56\/78\/9-epub$/) }
  end

  describe "#noid_from_root_path" do
    let(:root_path) { described_class.root_path_from_noid(noid, kind) }

    it { expect(described_class.noid_from_root_path(root_path, kind)).to eq noid }
  end

  describe "#remove_path_from_noid" do
    before do
      allow(DateTime).to receive(:now).and_return(9999)
    end

    it { expect(described_class.remove_path_from_noid(noid, kind)).to match(/\/12\/34\/56\/78\/TO-BE-REMOVED-9999-epub/) }
  end

  describe "#safe_path" do
    let(:root_dir) { Dir.mktmpdir }
    let(:outside_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
      FileUtils.remove_entry(outside_dir)
    end

    it 'returns a file within the root directory' do
      file = File.join(root_dir, 'inside.txt')
      File.write(file, 'inside')

      expect(described_class.safe_path(root_dir, 'inside.txt')).to eq(file)
    end

    it 'rejects a symlink that escapes the root directory' do
      File.write(File.join(outside_dir, 'outside.txt'), 'outside')
      File.symlink(File.join(outside_dir, 'outside.txt'), File.join(root_dir, 'linked.txt'))

      expect(described_class.safe_path(root_dir, 'linked.txt')).to be_nil
    end
  end
end
