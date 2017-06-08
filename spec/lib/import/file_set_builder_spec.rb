# frozen_string_literal: true

require 'rails_helper'
require 'import'

describe Import::FileSetBuilder do
  let(:builder) { described_class.new(file_set, user, attrs) }
  let(:user) { create(:user) }
  let(:attrs) { { 'title' => ['Miranda'], 'creator' => ['Waterhouse'] } }

  describe 'initialize' do
    let(:file_set) { FileSet.new }

    it 'has a file_set' do
      expect(builder.file_set).to eq file_set
    end

    it 'has a user' do
      expect(builder.user).to eq user
    end

    it 'has attributes' do
      expect(builder.attributes).to eq attrs
    end
  end

  describe '#run' do
    before do
      FileSet.destroy_all
      stub_out_redis
    end

    context 'when the builder runs successfully' do
      let(:file_set) do
        fs = FileSet.new('title' => ['old title'], 'creator' => ['old creator'])
        fs.apply_depositor_metadata(user.user_key)
        fs.save!
        fs
      end

      it 'updates the metadata for the file_set' do
        builder.run

        expect(FileSet.count).to eq 1
        fs = FileSet.first

        expect(fs.title).to eq ['Miranda']
        expect(fs.creator).to eq ['Waterhouse']
      end
    end
  end
end
