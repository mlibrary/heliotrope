# frozen_string_literal: true

require 'rails_helper'
require 'import/row_data'
require 'metadata_fields' unless defined?(MONO_FILENAME_FLAG)

RSpec.describe Import::RowData do
  let(:root_dir) { Dir.mktmpdir }
  let(:row_data) { described_class.new(false, root_dir) }
  let(:attrs) { {} }
  let(:errors) { {} }

  after { FileUtils.remove_entry(root_dir) }

  it 'keeps importing when referenced WebVTT files are missing, duplicated, or empty' do
    File.write(File.join(root_dir, 'duplicate.vtt'), 'first')
    FileUtils.mkdir_p(File.join(root_dir, 'nested'))
    File.write(File.join(root_dir, 'nested', 'duplicate.vtt'), 'second')
    FileUtils.touch(File.join(root_dir, 'empty.vtt'))

    row = {
      'File Name' => 'asset.jpg',
      'Title' => 'Asset',
      'Closed Captions' => "missing.vtt; duplicate.vtt\nempty.vtt"
    }

    row_data.field_values(:file_set, row, attrs, errors)

    expect(attrs['closed_captions']).to eq([
      'missing.vtt',
      'More than one file found with name: \'duplicate.vtt\'',
      nil
    ])
  end

  it 'stores the contents of an existing non-empty file in metadata' do
    contents = "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nLorem ipsum\n"
    File.write(File.join(root_dir, 'captions.vtt'), contents)

    row_data.field_values(:file_set, { 'Closed Captions' => 'captions.vtt' }, attrs, errors)

    expect(attrs['closed_captions']).to eq([contents])
  end
end
