# FOPS-1176 — EPUB 2 → 3.3 migration validation reports

These artifacts were produced by running the two EPUB 2.x sample inputs in
`../EPUB_2_sample_input/` through the new `EpubConversionService` (the same code
path `UnpackJob` invokes for an ingested EPUB), then validating the result with
EPUBCheck 5.3.0 and DAISY Ace 1.4.6.

## Files

For each ISBN (`9780252051760`, `9781944548292`):

- `<isbn>_migrated.epub` — the service's EPUB 3.3 output
- `<isbn>_epubcheck.txt` — full EPUBCheck 5.3.0 output
- `<isbn>_ace_summary.txt` — DAISY Ace violation counts by rule/impact
- `<isbn>_ace/report.json`, `report.html` — full Ace report
- `<isbn>_migration.log` — `EpubConversionService.epub2?` / `.migrate` results

## Results

**EPUBCheck 5.3.0:** both migrated EPUBs pass with
`0 fatals / 0 errors / 0 warnings / 0 infos`.

**DAISY Ace 1.4.6:** the targeted `link-in-text-block` rule is fully resolved
(2020 violations → 0 on `9780252051760`). The remaining Ace findings
(`epub-lang`, the `metadata-*` accessibility-metadata rules, and pre-existing
`empty-heading` markup in one book) are the harder rules that are explicitly
out of scope for this first pass.

## How to regenerate

EPUBCheck and Ace are NOT run by the service in production; they were only used
here as a validation aid. To reproduce locally (both tools must be on PATH):

```sh
# unpack an EPUB2 input, migrate it in place, then repackage + validate
mkdir /tmp/work && unzip -q ../EPUB_2_sample_input/9780252051760_version1.epub -d /tmp/work
bin/rails runner 'EpubConversionService.migrate("/tmp/work")'
( cd /tmp/work && zip -X -q /tmp/out.epub mimetype && zip -X -q -r /tmp/out.epub . -x mimetype )
epubcheck /tmp/out.epub
ace -o /tmp/ace /tmp/out.epub
```

