require 'i18n'
I18n.load_path << Dir[File.join(File.expand_path(File.dirname(__FILE__) + '/../locales'), '*.yml')]
I18n.load_path.flatten!

require 'bcp47/tag'
require 'bcp47/subtag'
require 'bcp47/language'
require 'bcp47/region'
