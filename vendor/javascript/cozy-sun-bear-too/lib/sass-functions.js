// minimal function that turns font-url() to url()
// to maintain compatibility with rails-sass
var sass = require('sass');

var font_url = function(filepath, done) {
  done(filepath);
};

module.exports = {
  'font-url($filename, $only-path: false)': function(filename, only_path, done) {
    font_url(filename.getValue(), function(url) {
      if(!only_path.getValue()) url = 'url(\'' + url + '\')';
      done(new sass.types.String(url));
    });
  },
  EOT: true
}