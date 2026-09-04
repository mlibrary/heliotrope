# Upgrading the vendored epub.js

The vendored source currently tracks upstream `v0.3.93` from
https://github.com/futurepress/epub.js. It is intentionally not a pristine npm
package: Heliotrope has local epub.js changes for PdeC/scrolling behavior,
page-list handling, scaling, and XML parsing.

## Upgrade procedure

1. Fetch the old and new upstream release tags.
2. Compare the current vendor tree to the old tag to identify local changes.
3. Apply the new tag with a three-way merge (`current`, old tag, new tag).
   Do not replace the vendor directory blindly.
4. Resolve conflicts in the local patch surface deliberately. The main files
   currently customized are:

   - `src/book.js`
   - `src/contents.js`
   - `src/epubcfi.js`
   - `src/layout.js`
   - `src/locations.js`
   - `src/managers/default/index.js`
   - `src/managers/helpers/stage.js`
   - `src/managers/views/iframe.js`
   - `src/navigation.js`
   - `src/pagelist.js`
   - `src/rendition.js`
   - `src/section.js`
   - `src/spine.js`
   - `src/utils/core.js`
   - `webpack.config.js`
   - `package.json` and `package-lock.json`

   The `cozy-sun-bear` overrides under
   `vendor/javascript/cozy-sun-bear/src/epubjs/` are separate from the
   upstream epub.js tree and must also be checked after an upgrade.
5. Confirm the package version and dependency metadata, then run the
   application asset build and repository checks.

## When to run which command

Use the smallest validation step that matches the change. A normal source or
stylesheet edit is usually picked up by the running development server; a
dependency or webpack-runtime change requires a clean compilation.

| Recent change or console indication | Action |
| --- | --- |
| Edited an epub.js source file or a `cozy-sun-bear` stylesheet while the development server is running | Wait for the server to report a successful rebuild. If it does not rebuild, run `bin/webpack` or restart `bin/shakapacker-dev-server`. |
| Changed `src/` files, `package.json`, `package-lock.json`, `webpack.config.js`, Babel settings, or Shakapacker configuration | Run `bin/webpack` after dependencies are installed. Restart `bin/shakapacker-dev-server` if it is running, because it does not reliably reload compiler configuration. |
| Changed dependency versions or the link between `cozy-sun-bear` and `epubjs` | Run `yarn install`, then remove `tmp/cache/webpacker` and rebuild. This refreshes the linked package and webpack module-resolution cache. |
| Console says `compiled successfully` and the browser loads the new bundle | No cache cleanup is needed. A hard reload is only needed if the browser still displays old behavior. |
| Console shows `__webpack_require__.h is not a function`, `chunk loaded`, a missing module, or a stack in a separately loaded `url.js`/webpack chunk | Treat the assets as mixed or stale. Stop the dev server, remove `public/packs` and `tmp/cache/webpacker`, restart the server, and hard-reload the browser. |
| The manifest points to an old asset or the browser requests a chunk that is not in `public/packs` | Remove generated packs and rebuild; do not edit the generated JavaScript manually. |
| Docker-backed specs fail before RSpec starts with a Docker daemon connection error | Start Docker and rerun `bin/compose --profile test run --rm test bundle exec rspec spec/`; this is an environment failure, not an epub.js test result. |

For the clean webpack reset described above:

```sh
rm -rf public/packs tmp/cache/webpacker
bin/shakapacker-dev-server
```

If only a one-off production-style compilation is needed, use `bin/webpack`
instead of starting the development server. Always inspect the console output
for the final compilation result before testing the reader in the browser.

## Verification

From the repository root:

```sh
bin/webpack
bundle exec rubocop
bin/compose --profile test run --rm test bundle exec rspec spec/
```

If Docker is unavailable, run the first two checks locally and run the full
RSpec command when the test services are available. The upstream Karma suite
requires the vendored JavaScript development dependencies and a headless
Chrome installation; it is supplementary to Heliotrope's reader/system specs.

Before committing, inspect both of these comparisons:

```sh
git diff --check
diff -qr vendor/javascript/epubjs /path/to/upstream-epubjs-tag
```

The second comparison should report only intentional Heliotrope customizations
and expected packaging/dependency differences.

