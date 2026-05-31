require 'noid/version'
require 'noid/minter'
require 'noid/template'

module Noid
  XDIGIT = %w(0 1 2 3 4 5 6 7 8 9 b c d f g h j k m n p q r s t v w x z)
  MAX_COUNTERS = 293

  class TemplateError < StandardError
  end
end
