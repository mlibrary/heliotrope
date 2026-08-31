# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebvttService do
  let(:english) { "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nLorem ipsum\n\n00:00:03.000 --> 00:00:04.000\ndolor sit amet\n" }
  let(:french) { "WEBVTT\nLanguage: fr\n\n00:00:01.000 --> 00:00:02.000\nLorem francais\n\n00:00:03.000 --> 00:00:04.000\ndolor sit amet\n" }

  it 'names exported entries with the NOID, field, and language' do
    expect(described_class.export_filenames('999999999', 'closed_captions', [english, french])).to eq(
      ['999999999_closed_captions.vtt', '999999999_closed_captions_fr.vtt']
    )
  end

  it 'adds an index when language-derived names collide' do
    expect(described_class.export_filenames('999999999', 'closed_captions', [english, english])).to eq(
      ['999999999_closed_captions.vtt', '999999999_closed_captions_2.vtt']
    )
  end
end
