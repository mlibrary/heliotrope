# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaptionService do
  let(:english) { "WEBVTT\n\n1\n00:00:01.000 --> 00:00:04.000\nHello world" }
  let(:french)  { "WEBVTT - fr\n\n1\n00:00:01.000 --> 00:00:04.000\nBonjour le monde" }
  let(:spanish) { "WEBVTT es\n\n1\n00:00:01.000 --> 00:00:04.000\nHola mundo" }
  let(:regional) { "WEBVTT - fr-CA\n\n1\n00:00:01.000 --> 00:00:04.000\nBonjour" }

  describe '.language_tag' do
    it 'returns nil for a bare WEBVTT signature' do
      expect(described_class.language_tag(english)).to be_nil
    end

    it 'reads a dash-delimited tag' do
      expect(described_class.language_tag(french)).to eq('fr')
    end

    it 'reads a whitespace-delimited tag' do
      expect(described_class.language_tag(spanish)).to eq('es')
    end

    it 'reads a tag with subtags' do
      expect(described_class.language_tag(regional)).to eq('fr-CA')
    end

    it 'ignores free-form header text that is not a language tag' do
      expect(described_class.language_tag("WEBVTT - This file has cues.")).to be_nil
    end

    it 'handles blank/nil input' do
      expect(described_class.language_tag(nil)).to be_nil
      expect(described_class.language_tag('')).to be_nil
    end
  end

  describe '.label_for' do
    it 'maps a known tag to a human label' do
      expect(described_class.label_for('fr')).to eq('French')
    end

    it 'maps a regional tag via its primary subtag' do
      expect(described_class.label_for('fr-CA')).to eq('French')
    end

    it 'falls back to the tag itself when unknown' do
      expect(described_class.label_for('xx')).to eq('xx')
    end

    it 'returns nil for a blank tag' do
      expect(described_class.label_for(nil)).to be_nil
    end
  end

  describe '.parse' do
    it 'returns [] for blank input' do
      expect(described_class.parse(nil)).to eq([])
      expect(described_class.parse([])).to eq([])
      expect(described_class.parse([''])).to eq([])
    end

    it 'assumes a lone untagged entry is the default (English) for backwards-compatibility' do
      expect(described_class.parse([english])).to eq(
        [{ language_tag: 'en', label: 'English', body: english }]
      )
    end

    it 'parses multiple tagged entries' do
      expect(described_class.parse([english, french])).to eq(
        [
          { language_tag: 'en', label: 'English', body: english },
          { language_tag: 'fr', label: 'French', body: french }
        ]
      )
    end

    it 'gives a nil tag/label to a secondary untagged entry' do
      expect(described_class.parse([french, english])).to eq(
        [
          { language_tag: 'fr', label: 'French', body: french },
          { language_tag: nil, label: nil, body: english }
        ]
      )
    end
  end

  describe '.for_language' do
    it 'returns nil when there are no entries' do
      expect(described_class.for_language([], 'en')).to be_nil
    end

    it 'returns the matching entry body' do
      expect(described_class.for_language([english, french], 'fr')).to eq(french)
    end

    it 'falls back to the first entry when the tag is not found' do
      expect(described_class.for_language([english, french], 'de')).to eq(english)
    end

    it 'falls back to the first entry when the tag is blank (legacy single-caption behaviour)' do
      expect(described_class.for_language([english], nil)).to eq(english)
    end
  end
end
