# PDF.js v5.0.375 Upgrade Guide

## Changes Made

### 1. Updated Module Script Tags
- Changed `<script src="/mozilla-pdf-viewer/build/pdf.mjs">` to `<script type="module" src="/mozilla-pdf-viewer/build/pdf.mjs">`
- Changed main script block from `<script type="text/javascript">` to `<script type="module">`

### 2. Replaced Custom Script Loader
- **Removed**: jQuery-based `$.loadScript()` function (doesn't work with ES modules)
- **Replaced with**: Native dynamic `import()` statement
- Changed: `$.loadScript("/web/viewer.mjs", function() { ... })` → `import("/web/viewer.mjs").then(() => { ... })`

### 3. Fixed Strict Mode Variable Declarations
ES modules enforce strict mode, which doesn't allow implicit globals. Fixed:
- `tts_info_modal` → `var tts_info_modal` in `_cozy_controls_bottom.js.erb`
- `share_link_modal` → `var share_link_modal` in `_cozy_controls_bottom.js.erb`
- `AnnotationTool` → `var AnnotationTool` in `show_pdf.html.erb`

See `STRICT_MODE_FIXES.md` for details on this issue.

### 4. Configured MIME Type for .mjs Files
Added to `config/initializers/mime_types.rb`:
```ruby
Rack::Mime::MIME_TYPES['.mjs'] = 'text/javascript'
```

This ensures `.mjs` files are served with the correct MIME type (`text/javascript`) instead of `text/plain`. Browsers enforce strict MIME type checking for ES module scripts per HTML spec.

**Important**: Requires server restart for initializer changes to take effect.

### 5. Fixed Promise Callback Context
Changed line 1183 in `show_pdf.html.erb`:
```javascript
// Before: this.PDFViewerApplication (undefined in promise callback)
// After:  self.PDFViewerApplication (correct closure variable)
self.pdfViewer = self.PDFViewerApplication.pdfViewer;
```

Inside the `PDFViewerApplication.open().then(function() {...})` callback, `this` is undefined. Changed to use `self` (which is captured in closure) instead.

See `PROMISE_CONTEXT_FIX.md` for details.

### 6. Fixed Page Centering in Scroll Mode
Added CSS rules to `app/assets/stylesheets/mozilla-pdf-viewer/cozy-honey-bear-reader.css`:

```css
/* PDF.js v5 scroll mode classes - ensure pages are centered */
.pdfViewer.scrollVertical .page,
.pdfViewer:not(.scrollHorizontal):not(.scrollWrapped) .page {
  margin-left: auto;
  margin-right: auto;
}

.pdfViewer.scrollVertical,
.pdfViewer:not(.scrollHorizontal):not(.scrollWrapped) {
  text-align: center;
}
```

**Why**: PDF.js v5 uses explicit scroll mode classes (`.scrollVertical`) instead of relying on no class. The existing CSS didn't target these new classes, causing pages to align left instead of center.

**Requires**: Asset recompilation (automatic in development, may need `rake assets:precompile` in production)

- `PDFViewerApplication.eventBus.on()` calls
- `PDFViewerApplication.eventBus.dispatch()` calls

### 4. **Locale/L10n System**
The localization system may have changed:
```html
<link rel="resource" type="application/l10n" href="/web/locale/locale.properties">
```
Verify locale files are still compatible.

### 5. **Viewer Preferences**
Check if these still work:
- `_ignoreDestinationZoom` property
- Scale modes ('auto', 'page-fit', 'page-width', etc.)
- Sidebar states and controls

### 6. **Custom Toolbar Integration**
The Mozilla PDF toolbar elements you're hiding/customizing may have changed. Verify:
- Element IDs still match
- CSS classes still match
- Button behaviors still work

## Testing Checklist

- [ ] PDF loads and displays correctly
- [ ] Page navigation (prev/next) works
- [ ] Zoom controls work (all scale modes)
- [ ] Search functionality works
- [ ] Table of Contents/Bookmarks work
- [ ] Thumbnails display
- [ ] Print functionality works
- [ ] Download functionality works
- [ ] Progress bar displays during loading
- [ ] Screen reader announcements work
- [ ] Hypothesis annotations work (if enabled)
- [ ] Page history (browser back/forward) works
- [ ] Deep linking to specific pages works
- [ ] Mobile/responsive layout works
- [ ] All cozy-sun-bear controls work

## Browser Console Errors to Watch For

Common errors you might see:

1. **"Failed to load module"** - Module path issues
2. **"PDFViewerApplication is not defined"** - Global exposure issue
3. **"Cannot read property 'eventBus' of undefined"** - API changes
4. **CORS errors** - Module loading security restrictions

## Rollback Plan

If issues arise, you can quickly rollback by:

1. Restore old pdf.js v3.x files to `public/mozilla-pdf-viewer`
2. Git revert the changes to `show_pdf.html.erb`:
   ```bash
   git checkout HEAD^ app/views/e_pubs/show_pdf.html.erb
   ```

## Additional Resources

- [PDF.js v5 Release Notes](https://github.com/mozilla/pdf.js/releases/tag/v5.0.375)
- [PDF.js Migration Guide](https://github.com/mozilla/pdf.js/wiki/Migration-Guide)
- [ES Modules Documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules)

## Notes

The main conceptual change is:
- **Before (v3.x)**: Classic scripts loaded synchronously, globals everywhere
- **After (v5.x)**: ES modules loaded asynchronously, explicit imports/exports

The changes made maintain backward compatibility with your cozy-sun-bear integration while adopting the new module system.




