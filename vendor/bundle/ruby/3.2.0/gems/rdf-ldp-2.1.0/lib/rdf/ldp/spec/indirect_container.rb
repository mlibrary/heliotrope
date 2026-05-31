require 'rdf/ldp/spec/direct_container'

shared_examples 'an IndirectContainer' do
  it_behaves_like 'a DirectContainer'

  shared_context 'with a relation' do
    before do
      subject.create(StringIO.new(graph.dump(:ntriples)),
                     'application/n-triples')
    end

    let(:graph) { RDF::Graph.new << inserted_content_statement }
    let(:relation_predicate) { RDF::Vocab::DC.creator }

    let(:inserted_content_statement) do
      RDF::Statement(uri,
                     RDF::Vocab::LDP.insertedContentRelation,
                     relation_predicate)
    end
  end

  describe '#inserted_content_relation' do
    it 'returns a uri' do
      subject.create(StringIO.new, 'application/n-triples')
      expect(subject.inserted_content_relation).to be_a RDF::URI
    end

    context 'with a relation' do
      include_context 'with a relation'

      it 'gives the relation' do
        expect(subject.inserted_content_relation).to eq relation_predicate
      end

      it 'raises an error when more than one exists' do
        new_statement = inserted_content_statement.clone
        new_statement.object = RDF::Vocab::DC.relation
        subject.graph << new_statement
        expect { subject.inserted_content_relation }
          .to raise_error RDF::LDP::NotAcceptable
      end
    end
  end

  describe '#add' do
    include_context 'with a relation'

    subject { described_class.new(uri, repo) }

    let(:repo) { RDF::Repository.new }
    let(:resource_uri) { RDF::URI('http://example.org/too-ticky') }
    let(:contained_resource) { RDF::LDP::RDFSource.new(resource_uri, repo) }

    context 'when no derived URI is found' do
      it 'raises NotAcceptable' do
        expect { subject.add(contained_resource) }
          .to raise_error RDF::LDP::NotAcceptable
      end

      it 'does not create the resource' do
        begin; subject.add(contained_resource); rescue; end
        expect(contained_resource).not_to exist
      end
    end

    context 'with expected predicate' do
      before { contained_resource.graph << statement }

      let(:target_uri) { contained_resource.to_uri / '#me' }

      let(:statement) do
        RDF::Statement(contained_resource.to_uri,
                       relation_predicate,
                       target_uri)
      end

      it 'when membership resource does not exist raises NotAcceptable' do
        new_resource = described_class.new(uri / 'new', repo)
        expect { new_resource.add(contained_resource) }
          .to raise_error RDF::LDP::NotAcceptable
      end

      context 'when the container exists' do
        it 'adds membership triple' do
          subject.add(contained_resource)
          expect(subject.graph.statements)
            .to include RDF::Statement(subject.to_uri,
                                       subject.membership_predicate,
                                       target_uri)
        end

        it 'for multiple predicates raises NotAcceptable' do
          new_statement = statement.clone
          new_statement.object = contained_resource.to_uri / '#you'
          contained_resource.graph << new_statement
          expect { subject.add(contained_resource) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        it 'for an LDP-NR raises NotAcceptable' do
          nr_resource = RDF::LDP::NonRDFSource.new(resource_uri, repo)
          expect { subject.add(nr_resource) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        context 'with membership resource' do
          before do
            subject.graph
                   .delete([uri, RDF::Vocab::LDP.membershipResource, nil])
            subject.graph << RDF::Statement(uri,
                                            RDF::Vocab::LDP.membershipResource,
                                            membership_resource)
          end

          let(:membership_resource) { uri }

          it 'raises error when resource does not exist' do
            new_resource = described_class.new(uri / 'new', repo)
            expect { new_resource.add(contained_resource) }
              .to raise_error RDF::LDP::NotAcceptable
          end

          context 'when the membership resource is not in the server' do
            let(:membership_resource) { uri / '#me' }

            it 'adds membership triple to container' do
              contained_resource.create(StringIO.new, 'application/n-triples')
              subject.add(contained_resource)

              expect(subject.graph.statements)
                .to include RDF::Statement(membership_resource,
                                           subject.membership_predicate,
                                           target_uri)
            end

            it 'removes membership triple to container' do
              contained_resource.create(StringIO.new, 'application/n-triples')

              subject.add(contained_resource)
              subject.remove(contained_resource)

              expect(subject.graph.statements)
                .not_to include RDF::Statement(membership_resource,
                                               subject.membership_predicate,
                                               target_uri)
            end
          end
        end
      end
    end
  end
end
