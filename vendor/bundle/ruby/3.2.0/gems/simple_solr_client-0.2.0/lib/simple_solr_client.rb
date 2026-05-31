module SimpleSolrClient

  ESCAPE_CHARS = '+-&|!(){}[]^"~*?:\\'
  ESCAPE_MAP   = ESCAPE_CHARS.split(//).each_with_object({}) {|x,h| h[x] = "\\" + x}
  ESCAPE_PAT   = Regexp.new('[' + Regexp.quote(ESCAPE_CHARS) + ']')

  # Escape those characters that need escaping to be valid lucene syntax.
  # Is *not* called internally, since how as I supposed to know if the parens/quotes are a
  # part of your string or there for legal lucene grouping?
  #
  def self.lucene_escape(str)
    esc = str.to_s.gsub(ESCAPE_PAT, ESCAPE_MAP)
  end


  # Where is the sample core configuration?
  SAMPLE_CORE_DIR = File.absolute_path File.join(File.dirname(__FILE__), '..', 'solr_sample_core')

end

require 'httpclient'
require 'forwardable'
require 'json'

require "simple_solr_client/version"

# Need to load core before client because of inter-dependencies resulting
# in 'require' recursion

require 'simple_solr_client/core'
require 'simple_solr_client/client'

