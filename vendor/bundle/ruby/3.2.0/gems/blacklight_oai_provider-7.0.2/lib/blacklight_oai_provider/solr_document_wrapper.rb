module BlacklightOaiProvider
  class SolrDocumentWrapper < ::OAI::Provider::Model
    attr_reader :document_model, :timestamp_field, :solr_timestamp, :limit, :granularity

    def initialize(controller, options = {})
      @controller      = controller
      @document_model  = @controller.blacklight_config.document_model
      @solr_timestamp  = document_model.timestamp_key
      @timestamp_field = 'timestamp' # method name used by ruby-oai
      @limit           = options[:limit] || 15
      @set             = options[:set_model] || BlacklightOaiProvider::SolrSet
      @granularity = options[:granularity] || OAI::Const::Granularity::HIGH

      @set.controller = @controller
      @set.fields = options[:set_fields]
    end

    def sets
      @set.all
    end

    def search_service
      @controller.search_service
    end

    def earliest
      builder = search_service.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} asc", rows: 1)
      response = search_service.repository.search(builder)
      timestamp_presence(response.documents.first)
    end

    def latest
      builder = search_service.search_builder.merge(fl: solr_timestamp, sort: "#{solr_timestamp} desc", rows: 1)
      response = search_service.repository.search(builder)
      timestamp_presence(response.documents.first)
    end

    def find(selector, options = {})
      return next_set(options[:resumption_token]) if options[:resumption_token]

      if selector == :all
        response = search_service.repository.search(conditions(options))

        if limit && response.total > limit
          return select_partial(BlacklightOaiProvider::ResumptionToken.new(options.merge(last: 0), nil, response.total))
        end
        response.documents
      else
        # search_service.fetch(selector).first.documents.first
        query = search_service.search_builder.where(id: selector).query
        search_service.repository.search(query).documents.first
      end
    end

    def select_partial(token)
      records = search_service.repository.search(token_conditions(token)).documents

      raise ::OAI::ResumptionTokenException unless records

      OAI::Provider::PartialResult.new(records, token.next(token.last + limit))
    end

    def next_set(token_string)
      raise ::OAI::ResumptionTokenException unless limit

      token = BlacklightOaiProvider::ResumptionToken.parse(token_string)
      select_partial(token)
    end

    def conditions(constraints) # conditions/query derived from options
      query = search_service.search_builder.merge(sort: "#{solr_timestamp} asc", rows: limit).query

      if constraints[:from].present? || constraints[:until].present?
        from_val = solr_date(constraints[:from])
        to_val = solr_date(constraints[:until], true)
        if from_val == to_val
          query.append_filter_query("#{solr_timestamp}:\"#{from_val}\"")
        else
          query.append_filter_query("#{solr_timestamp}:[#{from_val} TO #{to_val}]")
        end
      end

      query.append_filter_query(@set.from_spec(constraints[:set])) if constraints[:set].present?
      query
    end

    private

    def token_conditions(token)
      conditions(token.to_conditions_hash).merge(start: token.last)
    end

    def solr_date(time, end_val = false)
      return '*' if time.blank?
      case time
      when Date
        return granularize_date_value(time, end_val)
      when Time
        return granularize_time_value(time, end_val)
      else
        return time.to_s
      end
    end

    def granularize_date_value(value, end_val)
      return value.xmlschema[0..9] if granularity == OAI::Const::Granularity::LOW

      # get last second of the day if end of range, else use first second of day
      value = end_val ? Time.xmlschema((value + 1).xmlschema) - 1 : Time.xmlschema(value.xmlschema)
      granularize_time_value(value, end_val)
    end

    def granularize_time_value(value, end_val)
      value = value.utc
      return value.xmlschema[0..9] if granularity == OAI::Const::Granularity::LOW

      end_val ? value.xmlschema.sub(/(\:\d{2})Z$/, '\1.999Z') : value.xmlschema
    end

    def timestamp_presence(solr_doc)
      return solr_doc.timestamp.presence if solr_doc && solr_doc.timestamp
      Time.now.utc.to_s
    end
  end
end
