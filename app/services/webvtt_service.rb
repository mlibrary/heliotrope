# frozen_string_literal: true

# Our `closed_captions` and `visual_descriptions` FileSet metadata fields hold one or more WebVTT
# "files" (as plain text), which are served up by the overridden Hyrax::DownloadsController as though
# they were real derivative downloads (see app/overrides/hyrax/downloads_controller_overrides.rb).
#
# To support more than one language per field we expect each entry (except a lone, single entry, for
# backwards-compatibility) to declare its IETF/BCP-47 language tag in the WebVTT header, e.g.:
#
#   WEBVTT
#   Language: fr
#
# This is valid WebVTT, so all pre-existing single-entry captions (which just start with `WEBVTT`)
# continue to work untouched and are assumed to be English.
class WebvttService
  DEFAULT_LANGUAGE_TAG = 'en'

  # A small, dependency-free map of the language tags we actually expect to see. Unknown tags fall
  # back to the tag itself as a label (see `label_for`), so this only needs to grow as needed. Full
  # BCP-47 display-name resolution (CLDR etc.) would be overkill for this slowly-growing feature.
  LANGUAGE_LABELS = {
    'ar' => 'Arabic',
    'de' => 'German',
    'el' => 'Greek',
    'en' => 'English',
    'es' => 'Spanish',
    'fa' => 'Persian',
    'fr' => 'French',
    'he' => 'Hebrew',
    'hi' => 'Hindi',
    'it' => 'Italian',
    'ja' => 'Japanese',
    'ko' => 'Korean',
    'la' => 'Latin',
    'nl' => 'Dutch',
    'pl' => 'Polish',
    'pt' => 'Portuguese',
    'ru' => 'Russian',
    'tr' => 'Turkish',
    'uk' => 'Ukrainian',
    'zh' => 'Chinese'
  }.freeze

  # Captures a BCP-47 language tag from a case-insensitive Language key-value header line. The tag
  # has a 2-3 letter primary subtag with optional additional subtags (`fr`, `fr-CA`, `zh-Hant`).
  LANGUAGE_METADATA_REGEXP = /\A[ \t]*Language[ \t]*:[ \t]*(?<tag>[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*)[ \t]*\z/i
  CUE_TIMESTAMP_REGEXP = /\A[ \t]*(?:\d{2}:)?\d{2}:\d{2}\.\d{3}[ \t]+-->/

  # Parse a multi-value field's array of raw WebVTT strings into an ordered array of track hashes:
  #   [{ language_tag: 'en', label: 'English', body: "WEBVTT..." }, ...]
  # A lone entry with no declared tag is assumed to be the default (English); subsequent untagged
  # entries get a nil tag/label (they can still be served as the fallback, but won't render a <track>).
  def self.parse(entries)
    entries = Array(entries).reject(&:blank?)

    entries.map.with_index do |vtt, index|
      tag = language_tag(vtt)
      tag = DEFAULT_LANGUAGE_TAG if tag.blank? && index.zero?

      { language_tag: tag, label: label_for(tag), body: vtt }
    end
  end

  # Return the WebVTT body string for the requested language tag, falling back to the first entry
  # when the tag is blank or not found (which preserves the pre-multi-language behaviour).
  def self.for_language(entries, tag)
    parsed = parse(entries)
    return if parsed.empty?

    match = parsed.find { |track| track[:language_tag] == tag } if tag.present?
    (match || parsed.first)[:body]
  end

  # Extract the IETF/BCP-47 language tag from a single WebVTT string's header, or nil.
  def self.language_tag(vtt)
    lines = vtt.to_s.lines
    lines.shift

    lines.each do |line|
      break if CUE_TIMESTAMP_REGEXP.match?(line)

      match = LANGUAGE_METADATA_REGEXP.match(line.strip)
      return match[:tag] if match
    end

    nil
  end

  def self.label_for(tag)
    return if tag.blank?

    LANGUAGE_LABELS[tag] || LANGUAGE_LABELS[tag.split('-').first] || tag
  end

  # Generate stable names for WebVTT metadata files in an extracted monograph.
  def self.export_filenames(noid, metadata_name, entries)
    counts = Hash.new(0)

    Array(entries).map do |body|
      tag = language_tag(body)
      basename = [noid, metadata_name, tag].compact.reject(&:blank?).join('_')
      basename = "#{basename}.vtt"
      counts[basename] += 1
      counts[basename] == 1 ? basename : basename.sub('.vtt', "_#{counts[basename]}.vtt")
    end
  end
end
