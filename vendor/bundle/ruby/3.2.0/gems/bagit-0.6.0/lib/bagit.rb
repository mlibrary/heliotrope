# frozen_string_literal: true

# == About bagit.rb
# Author::    Francesco Lazzarino  (mailto:flazzarino@gmail.com)
# Functionality conforms to the BagIt Spec v0.96:
# http://www.cdlib.org/inside/diglib/bagit/bagitspec.html

require "bagit/bag"
require "bagit/version"
require "fileutils"
require "date"
require "logger"
module BagIt
  # The version of the BagIt specification the code is conforming to.
  SPEC_VERSION = "0.97"
end
