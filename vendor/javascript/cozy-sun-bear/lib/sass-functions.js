// minimal function that turns font-url() to url()
// to maintain compatibility with rails-sass
// Note: Dart Sass doesn't support custom functions via CLI the same way node-sass did
// This file is kept for reference but is no longer used with the sass CLI
var sass;
try {
  sass = require('sass');
} catch (e) {
  // sass module not available
}

var font_url = function(filepath, done) {
  done(filepath);
};

module.exports = {
  'font-url($filename, $only-path: false)': function(filename, only_path, done) {
    if (!sass || !sass.types) {
      throw new Error('sass module or sass.types is not available; ensure sass is properly installed and initialized');
    }
    font_url(filename.getValue(), function(url) {
      if(!only_path.getValue()) url = 'url(\'' + url + '\')';
      done(new sass.types.String(url));
    });
  },
  EOT: true
}