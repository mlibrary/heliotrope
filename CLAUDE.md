# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Heliotrope is the Rails application behind [Fulcrum](https://www.fulcrum.org), a scholarly publishing platform built by the University of Michigan Library. It extends [Hyrax](https://github.com/samvera/hyrax) (Samvera community repository software, itself built on Blacklight/ActiveFedora) with publisher branding, an EPUB/PDF web reader, restricted-access subscriptions, usage analytics (COUNTER reports), IIIF image delivery, and bulk import/export tooling.

Ruby 3.3.10, Rails on Hyrax 4.0. Storage is split across Fedora (binary/RDF repository for Works/FileSets), Solr (search index), and MySQL/MariaDB (everything relational: users, roles, subscriptions, counter stats). Redis + Resque run background jobs.

## Commands

### Docker (preferred — matches CI and is what most contributors use day to day)

Use `bin/compose` for all Docker Compose commands (auto-sets `DOCKER_DEFAULT_PLATFORM=linux/amd64` on Apple Silicon; `bin/dc` is a compatibility alias).

```
bin/compose up -d --build                                          # start app, db, solr, fcrepo, redis, resque
bin/compose down                                                   # stop everything

bin/compose --profile test up -d db redis solr-test fcrepo-test    # start test infra
bin/compose --profile test run --rm test                           # full suite (rubocop, ruumba, lib specs, rspec)
bin/compose --profile test run --rm test bundle exec rspec spec/path/to_spec.rb
bin/compose --profile test run --rm test bundle exec rubocop
bin/compose --profile test run --rm test bundle exec rails ruumba
bin/compose --profile test run --rm test bundle exec rails lib_spec
```

`config/database.yml` and `config/secrets.yml` are gitignored — copy from the `.sample` files before first run.

### Native (non-Docker)

```
bundle exec rails ci              # what CircleCI runs: rubocop, ruumba, lib_spec, solr_spec, then rspec against a live Fedora+Solr test server
bundle exec rubocop               # style check (rubocop-rails, rubocop-rspec)
bundle exec rubocop -A            # auto-fix
bundle exec rails ruumba          # style check for ERB view templates (app/views)
bundle exec rails lib_spec        # specs under lib/spec — cd lib && bundle exec rspec also works
bundle exec rspec spec/path/to_spec.rb   # single spec, requires Fedora/Solr test servers already running
```

To run rspec directly (not via `rails ci`), start test-mode Fedora/Solr first: `fcrepo_wrapper --config .wrap_conf/fcrepo_test` and `solr_wrapper --config .wrap_conf/solr_test`.

System specs (`spec/system/`) may be excluded from CircleCI for timing instability but still run fine locally under `rspec`/`rails ci`.

The `testing/` directory holds specs (`bundle exec rails testing_spec`) that run against a deployed `heliotrope-testing` environment, not local code — don't confuse these with `spec/`.

## Architecture

### Domain layer over Hyrax/ActiveFedora: Sighrax

`app/services/sighrax.rb` + `app/models/sighrax/` is a read-only, Solr-backed facade over Fedora objects. Rather than loading heavyweight ActiveFedora models, `Sighrax.from_noid`/`from_presenter`/`from_solr_document` build lightweight `Sighrax::Entity` subclasses (`Monograph`, `EpubEbook`, `PdfEbook`, `MobiEbook`, `AudiobookEbook`, `InteractiveMap`, `Resource`, `Work`, `Platform`, `Publisher`) directly from Solr documents. An invalid/missing noid resolves to a `NullEntity` rather than raising or returning nil — check `.valid?`, don't nil-check. `Sighrax` is also where role checks live (`platform_admin?`, `press_admin?`, `press_editor?`, `press_analyst?`) and where access-control decisions get made in combination with Greensub.

### Access control: Greensub + checkpoint gem

`app/models/greensub/` implements subscription-based access: `Product` (a purchasable bundle), `Component` (maps a product to a monograph/FileSet via noid), `License`/`FullLicense`/`ReadLicense` (grants), and `Licensee` (a concern mixed into `Institution` and `Individual`— the two things that can hold a license). A `Grant` record (`app/models/grant.rb`) ties a licensee to a product via the `checkpoint` gem's authorization tables. Institution access can also flow through `InstitutionAffiliation` (Shibboleth/SSO-based) rather than a direct license.

`AbilityCheckpoint` (CanCan) is intentionally a stub that grants `:manage, :all` — it exists to satisfy Hyrax's CanCan integration, but real authorization decisions for restricted content go through Sighrax/Greensub/checkpoint, not through CanCan abilities.

### E-reader stack

- `lib/e_pub/` — EPUB parsing/rendering: `Publication`, `Chapter`, `Cfi` (EPUB CFI navigation), `Search` (full-text search backed by SQLite/FTS — see the `bundle config build.sqlite3 ...` FTS4 flags in the README, needed for legacy EPUB search DBs), `Validator`.
- `lib/pdf_ebook/` — parallel structure for PDF-based ebooks (`Publication`, `Interval`).
- `lib/webgl/` and `e_pub/bridge_to_webgl.rb` — WebGL/interactive content support embedded in EPUBs.
- The reader itself is a separate single-page JS app pulled in as a gem, not built from `app/javascript` here.
- `app/models/opds/publication.rb` generates [Readium webpub-manifest](https://github.com/readium/webpub-manifest)/OPDS JSON for ebook distribution.

### Import/Export

`lib/import/` (`Importer`, `CsvParser`, `RowData`) and `lib/export/` (`Exporter`) implement Heliotrope's CSV-driven bulk metadata workflow for creating/updating Monographs and their FileSets — this is the primary ingest path publishers use, distinct from Hyrax's default single-item forms.

### Background jobs

Resque (not Sidekiq) via `app/jobs/`. Notable ones: `crossref_poll_job`/DOI submission, `aptrust_*_job` (APTrust preservation deposits), `handle_*_job` (persistent Handle.net identifiers for content), `counter_*`/`*_report_job` (COUNTER usage statistics), `characterize_job`/`fixity_job` (Hyrax file-processing overrides). `config/resque-pool.yml` defines worker pools; the `resque` Docker service runs them.

### Ancillary repos

Related business-logic repos referenced from this codebase (not vendored in): [Greensub](https://github.com/mlibrary/greensub) (standalone version of the subscription logic), [Turnsole](https://github.com/mlibrary/turnsole) (REST API Greensub talks to), [Heliotropium](https://github.com/mlibrary/heliotropium) and [Winterberry](https://github.com/mlibrary/winterberry) (production scripts/ingest pipeline).

## Conventions

- Use `Time.zone.today`, never `Date.today`.
- Service modules are namespaced as `FeatureService::ClassName` to avoid name collisions with Hyrax/ActiveFedora core classes.
- Private methods go below the `private`/`protected` keyword, indented one level deeper than the keyword itself (see `app/models/sighrax/entity.rb` for the pattern).
- `app/overrides/` holds monkey-patches/reopened classes for Hyrax internals — check there before assuming default Hyrax behavior applies.
- `rubocop.yml`/`.ruumba.yml` exclude `bin/`, `db/`, `fulcrum/`, `vendor/`, and `node_modules/` — don't expect style compliance there.
