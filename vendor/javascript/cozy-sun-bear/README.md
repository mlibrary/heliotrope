
# cozy-sun-bear

ePub widgets and support based around and with code from [epub.js](https://github.com/futurepress/epub.js)

## This is a vendored copy

This directory is an in-repo, dependency-only copy of `cozy-sun-bear`,
originally developed at https://github.com/mlibrary/cozy-sun-bear. It is no
longer a standalone project with its own build, test suite, or CI -- those
were removed when it was moved into heliotrope. Only the files actually
needed at runtime remain:

* `src/` -- the JS source (`cozy.js` is the entry point)
* `scss/` -- the stylesheets (`cozy.scss` is the entry point)
* `package.json` -- declares the runtime `dependencies` (e.g. `epubjs`,
  `jszip`, `lodash`) needed to resolve imports in `src/`

## How it's consumed

Heliotrope's root `package.json` depends on this package via:

```json
"cozy-sun-bear": "link:vendor/javascript/cozy-sun-bear"
```

`yarn install` symlinks `node_modules/cozy-sun-bear` to this directory, so
edits here take effect immediately without reinstalling. The `epubjs`
dependency is similarly vendored at `vendor/javascript/epubjs` and linked via
`"epubjs": "link:../epubjs"` in this package's own `package.json`.

The actual webpack entry point that imports this package is
`app/javascript/packs/cozy-sun-bear/cozy-sun-bear.js`, compiled by
Shakapacker as part of heliotrope's normal asset build -- there is no
separate build step for this package.

## Local CSS/JS development (no hard reloads)

When editing files here (e.g. `scss/cozy.scss` or anything in `src/`), use the
Shakapacker **dev server** so changes are picked up automatically. You should
never need an "empty cache and hard reload".

**One-time, after pulling a branch that touches this package:**

```sh
yarn install   # (re)links node_modules/cozy-sun-bear -> this directory
```

**Every session -- two terminals, both left running:**

```sh
# Terminal 1: Rails
bundle exec rails server

# Terminal 2: the asset watcher (must be running while you edit)
bin/shakapacker-dev-server
```

Then edit a file here and the browser updates on its own (HMR injects CSS
live; a normal reload is the most you'll ever need). No hard reload.

### Why this works / how it used to break

* This package is consumed through the symlink at `node_modules/cozy-sun-bear`,
  so webpack resolves edits via a `node_modules/...` path. `config/shakapacker.yml`
  narrows the dev-server `watch_options.ignored` glob to
  `**/node_modules/!(cozy-sun-bear)/**` so the watcher still sees these files.
* **Gotcha:** do not rely on a one-off `bin/shakapacker` build with the dev
  server *off*. Without the dev server, Rails' on-demand compile only checks its
  own watched paths (which exclude this vendored `node_modules` path), decides
  nothing changed, and serves a stale, browser-cached bundle -- which is the
  situation that used to force a hard reload.
* After changing `config/shakapacker.yml` itself, restart
  `bin/shakapacker-dev-server` for it to take effect.

### After dependency or webpack changes

The normal source-edit workflow above should not require a hard reload, but
dependency and compiler changes are different. After changing `package.json`,
`package-lock.json`, the linked `epubjs` version, Babel settings, webpack
configuration, or `config/shakapacker.yml`:

1. Run `yarn install` if package links or dependency versions changed.
2. Stop and restart `bin/shakapacker-dev-server` so it loads the new compiler
   configuration.
3. If the console reports a stale or mismatched chunk (for example,
   `__webpack_require__.h is not a function`, `chunk loaded`, or a missing
   module), clear generated output and restart the server:

   ```sh
   rm -rf public/packs tmp/cache/webpacker
   bin/shakapacker-dev-server
   ```

   Then hard-reload the browser once so it discards old runtime and chunk
   assets. This is an exception to the normal no-hard-reload workflow.

For the full vendored `epubjs` upgrade and customization-preservation
procedure, see [`vendor/javascript/epubjs/UPGRADING.md`](../epubjs/UPGRADING.md).

## Testing

There is no JS unit test suite here anymore (the old Karma/Mocha suite
depended on tooling -- and a Chrome binary -- that was never actually
installed as part of vendoring, so it wasn't runnable). Coverage of reader
behavior is expected to come from heliotrope's own RSpec system specs
(`spec/`), which exercise the reader through a real browser via Capybara.
