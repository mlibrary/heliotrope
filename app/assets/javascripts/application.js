// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
// The order of inclusion of jQuery is important –
// ensure you load jquery.turbolinks before turbolinks and after jquery.
//= require jquery
//= require jquery.turbolinks
// Include all your custom js between jquery-turbolinks.js
//= require jquery_ujs
//= require jquery-ui/datepicker
//= require 'short_monograph_description'
// and turbolinks.js
//= require turbolinks
// Required by Blacklight
//= require blacklight/blacklight
// Required by Heliotrope?
//= require leaflet
//= require leaflet-iiif
//= require 'edit_users'
//= require 'file_set_sort_date'
//= require 'disable_video_download'
//= require 'disable_audio_download'
//= require 'disable_image_download'
// Required by Hydra/Rails?
//= require_tree .
