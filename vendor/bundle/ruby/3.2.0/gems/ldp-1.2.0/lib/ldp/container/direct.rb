module Ldp
  class Container::Direct < Container::Basic
    def members
      return enum_for(:members) unless block_given?

      response_graph.query(subject: subject, predicate: member_relation).map do |x|
        yield rdf_source_for(x.object)
      end
    end

    def member_relation
      response_graph.first_object(predicate: RDF::Vocab::LDP.hasMemberRelation) || RDF::Vocab::LDP.member
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.DirectContainer
    end
  end
end
