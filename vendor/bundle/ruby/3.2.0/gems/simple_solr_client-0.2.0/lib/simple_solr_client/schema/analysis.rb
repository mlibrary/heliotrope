# Figure out how the field type will parse out tokens
# and change them in the analysis chain. Just calls the
# provided solr analysis endpoints
#
# To be mixed into FieldType

class SimpleSolrClient::Schema

  class InvalidTokenError < RuntimeError
    attr_accessor :resp


    def initialize(msg, resp)
      super(msg)
      @resp = resp
    end
  end

  module Analysis

    #https://lucene.apache.org/solr/4_1_0/solr-core/org/apache/solr/handler/FieldAnalysisRequestHandler.html
    def fieldtype_tokens(val, type)
      target = 'analysis/field'
      h      = {'analysis.fieldtype'  => name,
                'analysis.fieldvalue' => val,
                'analysis.query'      => val,
      }
      resp   = @core.get(target, h)

      ftdata = resp['analysis']['field_types'][name][type]
      rv     = []
      ftdata.last.each do |t|
        pos  = t['position'] - 1
        text = t['text']
        if rv[pos]
          rv[pos] = Array[rv[pos]] << text
        else
          rv[pos] = text
        end
      end
      rv
    end


    private :fieldtype_tokens

    # Get an array of tokens as analyzed/transformed at index time
    # Note that you may have multiple values at each token position if
    # you use a synonym filter or a stemmer
    # @param [String] ft the name of the fieldType (*not* the field)
    # @param [String] val the search string to parse
    # @return [Array] An array of tokens as produced by that index analysis chain
    #
    # @example Results when there's a stemmer
    #   c.fieldtype_index_tokens 'text', "That's Life"
    #     => [["that's", "that"], "life"]
    #
    def index_tokens(val)
      fieldtype_tokens(val, 'index')
    end


    def index_input_valid?(val)
      index_tokens(val)
    rescue SimpleSolrClient::Schema::InvalidTokenError, RuntimeError => e
      puts "IN HERE"
      require 'pry'; binding.pry
    end


    # Get an array of tokens as analyzed/transformed at query time
    # See #fieldtype_index_tokens
    def query_tokens(val)
      fieldtype_tokens(val, 'query')
    end


  end
end
