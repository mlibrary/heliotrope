# PR3 Plan: Collapse cozy-sun-bear variants, feature flags, one layout

## Step 0 — Investigation

### 1. Differences between `vendor/javascript/cozy-sun-bear/` and `cozy-sun-bear-too/`

#### A. Pure CSS/SCSS changes

| File | Change summary |
|------|----------------|
| `scss/cozy.scss` | `master` uses `@use` (Sass modules) + OpenDyslexic CDN font import; `too` uses legacy `@import`. `too` replaces the `.cozy-modal-preferences` floating-panel block with a CSS-grid sidebar system (`nm--toolbar`, `nm--reader`, `nm--panels`, `nm--actions`). Icon sizes drop: `2em`→`1.2em`, `2.5rem`→`2rem`. Active-state colors differ (`$brand-color`→`#8A96A1`). ~50 lines changed. |
| `scss/_modals.scss` | `$modal-header-bgcolor` value differs. `too` adds `.cozy-contents-toolbar { display:none }` and nested `dl/dt` styling. ~30 lines changed. |
| `scss/_loader.scss` | `master` uses `math.div()` (Sass modules API); `too` uses legacy `/` division. Visual output identical. ~10 lines changed. |
| `scss/_navigator.scss` | Differ (not fully diffed; minor). |
| `scss/_open-iconic.scss` | Differ (not fully diffed; minor). |

**Verdict**: Primarily CSS/SCSS. The `too` SCSS introduces the no-modal grid layout system that the epub_ebooks view (`nm--toolbar`, sidebar panels) depends on.

#### B. Template/markup changes to existing controls

| File | Change | ~Lines |
|------|--------|--------|
| `src/control/Control.BibliographicInformation.js` | Button template: `oi/info + " Info"` → icon only; adds `id` + `position:relative` on container | ~20 |
| `src/control/Control.Citation.js` | Minor markup changes | ~8 |
| `src/control/Control.Contents.js` | Icon: `menu`→`align-left`; adds open/close toggle logic (HELIO-4287); adds `closePanel` option | ~76 |
| `src/control/Control.Search.js` | Template: removes inline `<form>` wrapper, just a button; adds `updateContents` event listener | ~48 |
| `src/control/Modal.js` | Adds `modalContainer` option (modals can attach to custom DOM element); fires `resize` event on activate/deactivate; sets `data-modalActivated`; simplified focus trap | ~127 |
| `src/control/Control.Preferences.js` | **Major**: Button `oi/cog` → `Aa` text; removes `SliderControl` and `PreferencesConfig`; removes Font/Spacing fieldsets; removes "Set Defaults" button; removes `resetPreferencesToDefault()` | ~549 |

#### C. Behavioral changes to existing controls

| File | Change |
|------|--------|
| `src/reader/Reader.js` | `too` simplifies preference persistence: only saves `text_size`+`scale` per flow; removes font/word_spacing/letter_spacing/line_height/margins/paragraph_spacing. Removes `updateLiveStatus("Loading...")`. Removes font/spacing from `flowOptions` initialization. |
| `src/reader/Reader.EpubJS.js` | `too`: pre-paginated fakes locations by iterating spine. `master`: checks `no_continuous_scroll_isbns` list to force `default` manager for 2 specific ISBNs. Different scrolled-flow handling. |
| `src/utils/manglers.js` | `too`: table selector is `table:not([data-fulcrum-table="false"])`. `master`: more complex attribute override logic. |

#### D. Additive new features

**None in the CSB source itself.** Maps and notes functionality lives entirely in heliotrope views:
- **Maps**: `app/views/epub_ebooks/show.html.erb` + the Solr query in `EpubEbooksController` for `resource_type_tesim:interactive+map`
- **Notes**: `app/views/epub_ebooks/_cozy_controls_notes.html.erb` + `_cozy_pdec_notes.html.erb`

The no-modal layout (`nm--toolbar` etc.) is a CSS/SCSS change plus HTML in the view, not a CSB feature module.

#### E. Changes to reader CORE lifecycle

| File | Change |
|------|--------|
| `src/cozy.js` | `master` imports and registers `config` module; `too` does not |
| `src/epubjs/managers/continuous/scrolling.js` | `too`: adds `fraction=0.8` scaling, `calcuateWidth()`, and pre-paginated width/height scaling in `resize()`/`add()` |

**Files only in `master` (not in `too`)**:
- `src/config/PreferencesConfig.js` — preference config object (fonts, text sizes, spacing, etc.)
- `src/config/index.js`
- `src/utils/slider-control.js` — `SliderControl` class (range input with +/− buttons)

---

### 2. The two vendored epubjs directories

| Directory | Version | Used by |
|-----------|---------|---------|
| `vendor/javascript/epubjs/` | **v0.3.88** | Both `cozy-sun-bear` and `cozy-sun-bear-too` via `"epubjs": "file:../epubjs"` |
| `vendor/javascript/epubjs-patched/` | **v0.3.81** | **Nobody** — not referenced by either CSB variant's `package.json` |

`epubjs-patched` is a historical artifact. Both CSB variants already use `epubjs/` (v0.3.88). We can delete `epubjs-patched/` without any impact.

---

### 3. Heliotrope coupling to reader internals

#### DOM selectors targeting reader elements (outside vendor/)

**`app/views/epub_ebooks/show.html.erb`** and its partials (`_cozy_controls_*.html.erb`):
- `#epub` — reader mount container
- `.nm--toolbar`, `#action-close`, `#action-contents`, `#action-search`, `#action-notes`, `#action-map`
- `#modal-pdc-map` — map modal
- `#modal-notes-content section h4` — notes sections
- `.cozy-module-bottom` — where the tools panel is injected
- `.cozy-text-tools` — text tools panel
- `$(".cozy-module-bottom")`, `$('.cozy-text-tools')` — jQuery selectors

**`app/views/e_pubs/show.html.erb`** and its partials (`_cozy_controls_*.js.erb`):
- `#epub` — reader mount
- Standard reader controls via `cozy.control(...)` API
- `.annotator-frame`, `.annotator-collapsed` — annotation widget integration

#### Event names

**`app/views/epub_ebooks/show.html.erb`**:
- `mapClick_handler` — custom click handler for `.pdec_location` map links
- `resize` — dispatched by CSB `too`'s Modal.js on activate/deactivate

**`app/views/e_pubs/show.html.erb`**:
- `scrolltorange` — custom event from reader iframe
- `updateContents` — CSB-too fires this; `Control.Search.js` in `too` listens for it

#### postMessage payloads
None found in heliotrope views (not using postMessage).

#### cozy option/control names referenced by string
- `cozy.reader('reader', {...})` — mount element ID `'reader'`
- `cozy.control(...)` — various control types in the `_cozy_controls_*.js.erb` partials

#### Specs
- `spec/requests/e_pubs_spec.rb` (line 384–416): layout selection specs
- `spec/requests/epub_ebooks_spec.rb` (line 81): expects `csb_too_viewer`
- `spec/models/press_spec.rb` (lines 340–367): `use_new_epub_reader?` method spec

---

### 4. Request paths: csb_viewer vs csb_too_viewer

| | `csb_viewer` | `csb_too_viewer` |
|-|-------------|-----------------|
| Controller | `EPubsController#show` | `EpubEbooksController#show` |
| View | `app/views/e_pubs/show.html.erb` | `app/views/epub_ebooks/show.html.erb` |
| Mount element | `<div id="reader">` | `<div class="too" id="epub">` (different! — `nm--` layout) |
| Extra JS | None | head.js, jQuery 2.2.4, url-search-params (CDN) |
| Inline CSS | None | CSS grid for `#epub` (3-column grid layout) |
| Body tag | `tag.body class: press_presenter.press_subdomains` | Plain `<body>` |
| Pack loaded | `cozy-sun-bear/cozy-sun-bear` | `cozy-sun-bear-too/cozy-sun-bear-too` |
| Layout selection | Hard-coded to `csb_viewer` (no branching yet) | Hard-coded to `csb_too_viewer` |
| Analytics/CSP | Same `render 'shared/ga'` | Same `render 'shared/ga'` |
| Auth wrapping | Same Devise/ability checks | Same Devise/ability checks |

**Key difference discovered**: The `epub_ebooks` view uses a completely different mount element structure (the `nm--toolbar` + `nm--reader` no-modal grid) with `id="epub"`. The `e_pubs` view uses `id="reader"`. This means the two reader initializations call `cozy.reader('epub', ...)` and `cozy.reader('reader', ...)` respectively.

The inline CSS grid (`display: grid; grid-template-columns: min-content min-content 1fr`) in `csb_too_viewer` is structural to the `epub_ebooks` reader experience and must be preserved in the merged layout.

---

### 5. Snowflake book: maps and notes

**Identity**: *La Princesse de Clèves* — identified by:
1. **ISBN** `9781643150383` — used in `app/views/monograph_catalog/_index_monograph.html.erb` to route to `epub_ebook_path` instead of `epub_path`
2. **`EpubEbooksController`** — currently the only controller serving this book. The ISBN check in `setup` is commented out, implying the controller is being generalized.

**Maps feature**:
- Identified at runtime via Solr query: `resource_type_tesim:interactive+map` FileSet on the monograph
- If `@map_file_presenter` present → renders map iframe modal + `#action-map` button
- Degrades gracefully when absent (wrapped in `<% if @map_file_presenter.present? %>`)

**Notes feature**:
- Always rendered in `epub_ebooks/show.html.erb` via `render "cozy_controls_notes"` and `render "cozy_pdec_notes"` partials
- Does NOT degrade gracefully — always present in the epub_ebooks view

**CSB code involvement**: Maps/notes are 100% in heliotrope views. The CSB reader library is not aware of them. The no-modal toolbar (`nm--toolbar`) in the view uses `id="action-notes"` etc., which the view's own JavaScript handles.

**Snowflake identification in Ruby**: The `isbn == '9781643150383'` check in `_index_monograph.html.erb` is a hard-coded allow-list. No new Ruby changes needed — we keep this as-is with a `# TODO: replace with per-book flag` comment.

---

## Step 6 — Concrete plan

### Final directory layout

**Keep `vendor/javascript/cozy-sun-bear/`** (no move to `app/`).

Rationale: It's a vendored third-party library, not heliotrope application code. `vendor/javascript/` is the correct home. Moving it would change the `file:` references in `package.json` unnecessarily.

**Surviving tree** after the merge: `vendor/javascript/cozy-sun-bear/`, with:
- `src/` — merged source (see below)
- `scss/` — merged SCSS (see below)
- `dist/` — **deleted** (will be built by Shakapacker from source)
- `package.json` — rename to `cozy-sun-bear`, keep `"epubjs": "file:../epubjs"`

**Deleted**:
- `vendor/javascript/cozy-sun-bear-too/` — entire directory
- `vendor/javascript/epubjs-patched/` — entire directory (unused)
- `vendor/javascript/cozy-sun-bear/dist/` — both `.js` and `.css` built artifacts

### Feature-flag surface

```javascript
const features = Object.assign({
  restyledControls: true,   // too-style UI; default true (management approved)
  maps: false,              // interactive map button (pass-through; gated in Rails view)
  notes: false,             // notes panel button (pass-through; gated in Rails view)
}, (options && options.features) || {});
```

`maps` and `notes` exist only as pass-through flags from Rails → JS. The CSB library does not implement maps/notes functionality itself; those are in heliotrope views. The flags are defined here so Rails can communicate intent and so future per-reader guards can be added without another API change.

### Where each flag is guarded in JS

**`restyledControls`**:
- Primary guard: in `Reader.js` initialization, add CSS class `cozy-classic` to the reader root element when `restyledControls === false`. This scopes all SCSS rollback rules.
- Secondary guard: in `Control.Preferences.js`, the `Aa` button template vs icon glyph, and the TextSize-only vs Font+Spacing fieldsets, are guarded by `if (this._reader.features.restyledControls)`.
- Other controls (`BibliographicInformation`, `Contents`, `Search`) have small template changes that are CSS-class-compatible (icon choice is styleable).

**`maps`** and **`notes`**: No guards in CSB JS code. Rails view conditionally renders the button HTML.

### Passing flags from Rails to JS

Use a `data-cozy-features` JSON attribute on the reader mount element:

```erb
<div id="reader" data-cozy-features="<%= @cozy_features.to_json %>"></div>
```

Then in the JS pack entry point, or in the view's reader init:

```javascript
const mountEl = document.getElementById('reader');
const features = JSON.parse(mountEl.dataset.cozyFeatures || '{}');
cozy.reader('reader', { features: features, ... });
```

`@cozy_features` is assembled in the controller or view helper:

```ruby
@cozy_features = {
  restyledControls: @press.use_new_epub_reader?,
  maps: @map_file_presenter.present?,
  notes: false  # TODO: per-book flag
}
```

### Snowflake book identification

**No new Ruby code.** The `_index_monograph.html.erb` ISBN-based routing to `epub_ebook_path` stays as-is with an added comment:

```ruby
# TODO: replace with a real per-book flag once the metadata schema supports it.
princess_de_cleves = @press.use_new_epub_reader ||
  (@monograph_presenter.isbn.any? { |isbn| isbn.delete("^0-9") == '9781643150383' })
```

The `EpubEbooksController` stays dedicated to epub ebooks but now uses the single layout.

### Files/directories deleted at the end

- `vendor/javascript/cozy-sun-bear-too/` (entire directory)
- `vendor/javascript/epubjs-patched/` (entire directory)
- `vendor/javascript/cozy-sun-bear/dist/` (entire directory)
- `app/views/layouts/csb_too_viewer.html.erb`
- `app/javascript/packs/cozy-sun-bear-too/` (entire directory)

### Layout selection code path after this PR

**ONE layout**: `app/views/layouts/csb_viewer.html.erb`

- Both `e_pubs/show.html.erb` (line 191) and `epub_ebooks/show.html.erb` (line 273) render `layouts/csb_viewer`.
- `csb_viewer.html.erb` loads the single `cozy-sun-bear` pack (CSS + JS).
- The inline CSS grid for `#epub` (from `csb_too_viewer`) is absorbed into `csb_viewer` — it won't affect the `#reader` element used by `e_pubs`, so it's safe to include.
- `use_new_epub_reader` drives **`restyledControls: true|false`** in `@cozy_features`, NOT layout choice.

### Build-pipeline changes

1. Add `sass` and `sass-loader` to heliotrope's `package.json` (no version present).
2. Update `config/webpack/webpack.config.js` to add a SCSS rule alongside the CSS rule.
3. Rewrite `app/javascript/packs/cozy-sun-bear/cozy-sun-bear.js` to import `cozy-sun-bear/src/cozy.js` instead of the `dist/` artifact.
4. Rewrite `app/javascript/packs/cozy-sun-bear/cozy-sun-bear.css` to import the SCSS entry.
5. Delete `app/javascript/packs/cozy-sun-bear-too/` directory.
6. Remove `"cozy-sun-bear-too": "file:vendor/javascript/cozy-sun-bear-too"` from heliotrope's `package.json`.

**Running the build locally**:
```bash
bin/shakapacker          # or: NODE_ENV=production bin/shakapacker
# or in development:
bin/shakapacker-dev-server
```

### Sequence of commits

1. `PR3 plan: investigation + concrete approach` — this document
2. `PR3 step1: merge too source into cozy-sun-bear, add features object` — JS convergence
3. `PR3 step2: build cozy-sun-bear from source through Shakapacker` — build pipeline
4. `PR3 step3: one layout, feature JSON from Rails` — Rails side

---

## 7. Risks not anticipated

1. **Mount element ID mismatch**: `e_pubs` uses `id="reader"`, `epub_ebooks` uses `id="epub"`. After the merge, both views remain in place with their own `cozy.reader(...)` call. No change needed here — the views are independent.

2. **jQuery 2.2.4 CDN dependency in csb_too_viewer**: The `epub_ebooks/show.html.erb` uses `$(".cozy-module-bottom")` and `$('.cozy-text-tools')` jQuery selectors. These will need to remain either via CDN or be converted to vanilla JS. Currently kept as CDN includes in the merged layout (absorbed from `csb_too_viewer`).

3. **`@use` vs `@import` in SCSS**: `master`'s SCSS uses `@use` (Sass modules, requires `sass` ≥ 1.23) but `too`'s uses legacy `@import`. We take `too` as baseline so we use `@import`. The `sass-loader` + `sass` will handle legacy `@import` fine. OpenDyslexic CDN import is also in `master` only; it must be preserved for presses using that font. Solution: add the OpenDyslexic `@import url(...)` to the merged SCSS.

4. **`no_continuous_scroll_isbns` list in Reader.EpubJS.js**: `master` has a hard-coded list of 2 ISBNs that force `default` scroll manager. `too` removes this. The merged code takes `too` as baseline but should preserve the ISBN list in a comment pending investigation of whether those books need it.

5. **`epubjs-patched` (v0.3.81) may have been used historically**: It's not referenced now, but if any production book was served against it and had stored CFI positions, those positions might not be compatible with v0.3.88. This is a data concern, not a code concern for this PR.

6. **Spec updates required**: `spec/requests/e_pubs_spec.rb` (line 415) expects `csb_too_viewer` when `use_new_epub_reader: true`. After this PR, it should expect `csb_viewer` (the single layout). `spec/requests/epub_ebooks_spec.rb` (line 81) also expects `csb_too_viewer` — update to `csb_viewer`. Both specs are GREEN after the change.

7. **`cozy-sun-bear-too` package name in merged package.json**: The merged tree must be named `cozy-sun-bear` (not `cozy-sun-bear-too`) so heliotrope's `import cozy from "cozy-sun-bear"` resolves correctly.
