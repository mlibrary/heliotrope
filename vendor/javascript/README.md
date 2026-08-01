# vendor/javascript

This directory contains verbatim vendored copies of the two upstream refs of
[mlibrary/cozy-sun-bear](https://github.com/mlibrary/cozy-sun-bear) and their
[mlibrary/epub.js](https://github.com/mlibrary/epub.js) transitive dependency,
included here so that `heliotrope` no longer needs to fetch git-URL npm
dependencies at install time.

## Vendored packages

| Directory | Upstream repo | Branch | Commit SHA |
|---|---|---|---|
| `cozy-sun-bear/` | `mlibrary/cozy-sun-bear` | `master` | `3057e4be1e8c3d02551b7a1be378f6dc4e69d972` |
| `cozy-sun-bear-too/` | `mlibrary/cozy-sun-bear` | `too` | `bd8eac3c800c4be3cf14ed045560856f4633b2c5` |
| `epubjs/` | `mlibrary/epub.js` | `cozy-sun-bear-2026` | `90d69c4ed0b969a13902aa928d5a3bfdf826d9f0` |
| `epubjs-patched/` | `mlibrary/epub.js` | `patched` | `a062b5d803fab97945bd94a1520cfbb3e0ffdb99` |

## What was changed

- `cozy-sun-bear-too/package.json`: the `name` field was changed from
  `cozy-sun-bear` to `cozy-sun-bear-too` so that yarn treats them as two distinct
  local packages.
- `cozy-sun-bear/package.json` and `cozy-sun-bear-too/package.json`: the
  `epubjs` dependency was changed from a `git+https://` URL to a `file:` path
  pointing at the corresponding vendored epubjs directory.
- `epubjs/package.json` and `epubjs-patched/package.json`: the `prepare`
  lifecycle script was removed. The upstream `prepare` builds epubjs' own
  distribution bundles, which is not needed when epubjs is consumed as a
  source-level dependency by cozy-sun-bear (via webpack). Removing it prevents
  yarn from failing with a webpack error during `yarn install`.

No other files in any vendored tree have been modified.

The prebuilt `dist/` output for cozy-sun-bear is intentionally included so that
the existing Shakapacker packs (`import "cozy-sun-bear/dist/cozy-sun-bear.css"`
etc.) continue to work without changes.

`node_modules/`, `.git/`, and the upstream `package-lock.json` are excluded
from all vendored copies.

**Note:** These directories will be reorganized in a follow-up PR that will
build CSB source directly through Shakapacker and remove the `dist/` artifacts.
