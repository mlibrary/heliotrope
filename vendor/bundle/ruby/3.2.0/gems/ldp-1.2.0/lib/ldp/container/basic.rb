module Ldp
  class Container::Basic < Container
    def members
      return enum_for(:members) unless block_given?
      contains.each { |k, x| yield x }
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.BasicContainer
    end
  end
end
