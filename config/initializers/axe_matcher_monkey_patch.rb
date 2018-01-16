# frozen_string_literal: true

# The axe-matcher 1.3.3 gem uses javascript from axe-core called
# axe.min.js which is included with that gem. Unfortunatly it doesn't
# play well with some of the rails js, specifically require.js and
# almond giving the error: "incorrect module build, no module name.""
# See https://github.com/requirejs/almond#incorrect-module-build-no-module-name
#
# So we'll include our own axe.js (not min) for now and we'll change line 24 from
#   define([], function() {
# to
#   define('axe' [], function() {
#
# to fix it.
#
# The axe-matchers should only be run inside the system specs where we're checking for
# accessibilty issues. See #1431
#
# axe.min.js is from axe-matchers-1.3.3/node_modules/axe-core/axe.min.js
# (node_modules gets generated when you install the gem)
# But the axe.js modified in /vendor is directly from https://github.com/dequelabs/axe-core

module Axe
  class Configuration
    def jslib
      @jslib_path = Rails.root.join("vendor", "assets", "javascripts", "axe.2.6.1.define-fix.js")
      @jslib ||= Pathname.new(@jslib_path).read
    end
  end
end
