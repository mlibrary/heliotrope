module RDF
  module LDP
    ##
    # Provides an interaction model registry.
    class InteractionModel
      class << self
        ##
        # Interaction models are in reverse order of preference for POST/PUT
        # requests; e.g. if a client sends a request with Resource, RDFSource,
        # oand BasicContainer headers, the server gives a basic container.
        #
        # Interaction models are initialized in the correct order, but with no
        # class registered to handle them.
        @@interaction_models = {
          RDF::LDP::RDFSource.to_uri         => nil,
          RDF::LDP::Container.to_uri         => nil,
          RDF::Vocab::LDP.BasicContainer     => nil,
          RDF::LDP::DirectContainer.to_uri   => nil,
          RDF::LDP::IndirectContainer.to_uri => nil,
          RDF::LDP::NonRDFSource.to_uri      => nil
        }

        ##
        # Register a new interaction model for one or more Link header URIs.
        # klass.to_uri will automatically be registered.
        #
        # @param [RDF::LDP::Resource] klass  the implementation class to
        #   register
        # @param [Hash <Symbol, *>] opts   registration options:
        #   :default [true, false]  if true, klass will become the new default
        #     klass for unrecognized Link headers
        #   :for [RDF::URI, Array<RDF::URI>]  additional URIs for which klass
        #     should become the interaction model
        #
        # @return [RDF::LDP::Resource] klass
        def register(klass, opts = {})
          unless klass.ancestors.include?(RDF::LDP::Resource)
            raise ArgumentError,
                  'Interaction models must subclass `RDF::LDP::Resource`'
          end
          @@default = klass if opts[:default] || @@default.nil?
          @@interaction_models[klass.to_uri] = klass
          Array(opts[:for]).each do |model|
            @@interaction_models[model] = klass
          end
          klass
        end

        ##
        # Find the appropriate interaction model given a set of Link header
        # URIs.
        #
        # @param [Array<RDF::URI>] uris
        #
        # @return [Class] a subclass of {RDF::LDP::Resource} that most narrowly
        #   matches the supplied `uris`, or the default interaction model if
        #   nothing matches
        def find(uris)
          match = @@interaction_models.keys.reverse.find { |u| uris.include? u }
          self.for(match) || @@default
        end

        ##
        # Find the interaction model registered for a given uri
        #
        # @param [RDF::URI] uri
        #
        # @return [Class] the {RDF::LDP::Resource} subclass registered to `uri`
        def for(uri)
          @@interaction_models[uri]
        end

        ##
        # The default registered interaction model
        def default
          @@default
        end

        ##
        # Test an array of URIs to see if their interaction models are
        # compatible (e.g., all of the URIs refer either to RDF models or
        # non-RDF models, but not a combination of both).
        #
        # @param [Array<RDF::URI>] uris
        # @return [TrueClass or FalseClass]  true if the models specified by
        #   `uris` are compatible
        def compatible?(uris)
          classes        = uris.collect { |m| self.for(m) }
          (rdf, non_rdf) =
            classes.compact.partition { |c| c.ancestors.include?(RDFSource) }

          rdf.empty? || non_rdf.empty?
        end
      end
    end
  end
end
