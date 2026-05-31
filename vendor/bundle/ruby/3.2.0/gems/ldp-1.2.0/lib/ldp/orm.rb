module Ldp
  class Orm
    attr_reader :resource
    attr_reader :last_response

    def initialize resource
      @resource = resource
    end

    def subject_uri
      resource.subject_uri
    end

    def new?
      resource.new?
    end

    def persisted?
      !new?
    end

    def graph
      Ldp.instrument 'graph.orm.ldp', subject: subject_uri do
        resource.graph
      end
    end

    def value predicate
      graph.query([subject_uri, predicate, nil]).map do |stmt|
        stmt.object
      end
    end

    def query *args, &block
      Ldp.instrument 'query.orm.ldp', subject: subject_uri do
        graph.query *args, &block
      end
    end

    def reload
      Ldp.instrument 'reload.orm.ldp', subject: subject_uri do
        Ldp::Orm.new resource.reload
      end
    end

    def create
      Ldp.instrument 'create.orm.ldp', subject: subject_uri do
        # resource.create returns a reloaded resource which causes any default URIs (e.g. "<>")
        # in the graph to be transformed to routable URIs
        Ldp::Orm.new resource.create
      end
    end

    def save
      Ldp.instrument 'save.orm.ldp', subject: subject_uri do
        response = create_or_update

        response.success?
      end
    rescue Ldp::HttpError
      false
    end

    def save!
      result = create_or_update

      if result.is_a? RDF::Enumerable
        raise Ldp::GraphDifferenceException, 'Graph failed to persist', result
      end

      result
    end

    def delete
      Ldp.instrument 'delete.orm.ldp', subject: subject_uri do
        resource.delete
      end
    end

    private

    def create_or_update
      @last_response = resource.save
    rescue Ldp::HttpError => e
      @last_response = e
      logger.debug e
      raise e
    end

    def logger
      Ldp.logger
    end
  end
end
