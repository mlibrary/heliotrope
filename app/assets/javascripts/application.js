// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require common
//= require_tree ./common
//= require popper
//require twitter/typeahead -- This is supposed to be here for hyrax4 but we don't use it and it causes an error, so left "commented" out (no =)
//= require bootstrap
//= require jquery.dataTables
// require jquery-ui/widgets/datepicker  -- Does heliotrope need this? Is it an old hyrax thing? I don't know
//= require dataTables.bootstrap4
// note: blacklight/blacklight must always be included after turbolinks
//= require blacklight/blacklight
// require blacklight_gallery -- This is also in hyrax4 upgrade but causes an error: couldn't find file 'blacklight_gallery' with type 'application/javascript'
//= require jszip.min
//= require_tree ./application
//= require application_survey
//= require hyrax
//
// [heliotrope override]
// HELIO-4598, https://github.com/samvera/hyrax/issues/6361
//= require hyrax/heliotrope_member_override
